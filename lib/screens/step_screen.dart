import 'package:flutter/material.dart';
import 'dart:async';
import 'package:guardian_angel/l10n/app_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';
import '../core/duration_formatting.dart';
import '../core/number_formatting.dart';
import '../core/text_normalization.dart';
import '../widgets/gradient_button.dart';
import '../widgets/share_location_sheet.dart';
import '../services/database_service.dart';
import '../services/protocol_loader.dart';
import '../services/tts_service.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';


class StepScreen extends StatefulWidget {
  final String emergencyId;
  final String emergencyTitle;
  final Color emergencyColor;
  final int? incidentLogId;

  const StepScreen({
    super.key,
    required this.emergencyId,
    required this.emergencyTitle,
    required this.emergencyColor,
    this.incidentLogId,
  });

  @override
  State<StepScreen> createState() => _StepScreenState();
}

class _StepScreenState extends State<StepScreen> {
  List<dynamic> _steps = [];
  List<dynamic> _warnings = [];
  int _currentStep = 0;
  bool _loading = true;
  bool _completed = false;
  String? _errorMessage;
  String? _loadedLocale; // tracks which locale's JSON is currently loaded
  bool _ttsEnabled = true;
  bool _ttsKnown = false; // true once tts_enabled pref has been read
  final ScrollController _cardScrollController = ScrollController();
  bool _showScrollFade = false;
  int _maxVisitedStep = 0;
  DateTime? _sessionStartedAt;
  DateTime? _sessionEndedAt;
  DateTime? _stepStartedAt;
  List<int> _stepDurations = [];
  bool _locationSharing = false; // guard against double-tap on location button
  // ── Hands-free state ──
  final SpeechToText _handsFree = SpeechToText();
  bool _handsFreeEnabled = false;
  bool _handsFreeListening = false;
  bool _handsFreeReady = false;
  // Global Free Mode setting captured at load; used to re-honor the setting on
  // protocol restart instead of forcing it off.
  bool _freeModeDefault = true;
  // Re-entrancy guard: multiple restart paths (onStatus, onError, onComplete)
  // can fire near-simultaneously — only one start sequence runs at a time.
  bool _handsFreeStarting = false;
  // Watchdog that restarts the recognizer if it ever stops while Free Mode is
  // still on — a reliable backstop for whatever lifecycle edge the callback
  // re-arms miss.
  Timer? _handsFreeWatchdog;
  // Guards against acting on the same command twice within one listen session
  // (partial result, then final result of the same phrase).
  bool _commandActedThisSession = false;
  // When narration started. The watchdog clears a stale _narrating that never
  // got an onComplete (e.g. playback preempted by stop()), so the mic can't
  // latch closed forever.
  DateTime? _narrationStartedAt;

  // ── Command vocabularies (normalized at match time) ──
  // English includes common mis-recognitions; Arabic includes MSA + dialectal
  // forms and frequent recognizer variants, since on-device Arabic STT is noisy.
  static const _nextWords = <String>[
    // English
    'next', 'nex', 'nets', 'neck', 'text',
    'continue', 'move on', 'go ahead', 'forward', 'go forward',
    'proceed', 'okay', 'ok', 'done', 'yes',
    // Hebrew
    'הבא', 'המשך', 'קדימה', 'כן',
    // Arabic (MSA + dialect + variants)
    'التالي', 'تالي', 'التالية', 'استمر', 'كمل', 'للأمام', 'امشي', 'يلا',
    'قدام', 'روح',
  ];

  static const _previousWords = <String>[
    // English
    'previous', 'prev', 'back', 'go back', 'before',
    'last', 'return', 'undo',
    // Hebrew
    'הקודם', 'אחורה', 'חזור',
    // Arabic (MSA + dialect + variants)
    'السابق', 'سابق', 'ارجع', 'رجع', 'رجوع', 'للخلف', 'وراء', 'ورا',
  ];

  // Normalized once at class load — the matcher runs on every speech result
  // (including streaming partials), so don't re-normalize the constants each
  // time.
  static final List<String> _nextWordsNorm =
      _nextWords.map(normalizeForMatch).toList(growable: false);
  static final List<String> _previousWordsNorm =
      _previousWords.map(normalizeForMatch).toList(growable: false);
  // True while a step is being narrated. The mic is muted during narration so
  // the recognizer doesn't transcribe the app's own voice and trigger false
  // Next/Back commands; listening resumes when narration completes.
  bool _narrating = false;
  StreamSubscription<void>? _ttsCompleteSub;

  void _checkScrollable() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_cardScrollController.hasClients) return;
      final show = _cardScrollController.position.maxScrollExtent > 1;
      if (show != _showScrollFade) setState(() => _showScrollFade = show);
    });
  }

  @override
  void initState() {
    super.initState();
    // When a step finishes narrating, re-open the mic for the next command.
    _ttsCompleteSub = TtsService.instance.onComplete.listen((_) {
      if (!mounted) return;
      _narrating = false;
      _narrationStartedAt = null;
      // Audio finished — open the mic for Free Mode (if enabled).
      _maybeStartHandsFree();
    });
    // Backstop: every couple of seconds, if Free Mode is on but the recognizer
    // has stopped (silence timeout, dropped session, etc.), restart it — and
    // keep the UI "listening" flag honest with the real recognizer state.
    _handsFreeWatchdog = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      // Clear a stale narration flag that never received an onComplete (e.g.
      // playback preempted by stop()), so the mic can't latch closed forever.
      if (_narrating &&
          _narrationStartedAt != null &&
          DateTime.now().difference(_narrationStartedAt!).inSeconds > 30) {
        _narrating = false;
        _narrationStartedAt = null;
      }
      final reallyListening = _handsFree.isListening;
      if (_handsFreeListening != reallyListening && !_handsFreeStarting) {
        setState(() => _handsFreeListening = reallyListening);
      }
      if (_handsFreeEnabled &&
          !_completed &&
          !_narrating &&
          !_handsFreeStarting &&
          !reallyListening) {
        _startHandsFreeListening();
      }
    });
    _cardScrollController.addListener(() {
      final atBottom =
          _cardScrollController.offset >=
          _cardScrollController.position.maxScrollExtent - 1;
      final shouldShow = !atBottom;
      if (shouldShow != _showScrollFade) {
        setState(() => _showScrollFade = shouldShow);
      }
    });
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      final ttsEnabled = prefs.getBool('tts_enabled') ?? true;
      // Free Mode follows the global setting (default on) each time a protocol
      // opens. Manual toggles inside the protocol change only this session and
      // never write back here, so the next protocol honors the setting again.
      final freeMode = prefs.getBool('free_mode_enabled') ?? true;
      _freeModeDefault = freeMode;
      setState(() {
        _ttsEnabled = ttsEnabled;
        _ttsKnown = true;
        _handsFreeEnabled = freeMode;
      });
      // If the protocol finished loading before the pref was known,
      // speak the first step now. Otherwise _loadProtocol handles it.
      if (ttsEnabled && _steps.isNotEmpty) {
        _narrating = true;
      _narrationStartedAt = DateTime.now();
        TtsService.instance.speak(
          widget.emergencyId,
          _steps[0]['step'] as int,
          TtsService.langCodeFor(_loadedLocale ?? 'en'),
        );
      }
      // Free Mode stays "ready" while the first step narrates; the mic only
      // opens when nothing is playing (e.g. TTS off). When TTS is on, the
      // onComplete handler opens the mic once the audio finishes.
      _maybeStartHandsFree();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeCode = Localizations.localeOf(context).languageCode;
    if (_loadedLocale != localeCode) {
      _loadedLocale = localeCode;
      _loadProtocol(localeCode);
    }
  }

  /// Tries to load the protocol for [localeCode]; falls back to English.
  Future<void> _loadProtocol(String localeCode) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _currentStep = 0;
      _completed = false;
      _maxVisitedStep = 0;
      _sessionStartedAt = null;
      _sessionEndedAt = null;
      _stepStartedAt = null;
      _stepDurations = [];
    });

    final result = await ProtocolLoader.tryLoad(widget.emergencyId, localeCode);
    final error = result.error;
    if (error != null) {
      if (!mounted) return;
      setState(() {
        _errorMessage = switch (error) {
          ProtocolLoadError.failed => AppLocalizations.of(
            context,
          )!.stepErrorFailed,
          ProtocolLoadError.invalid => AppLocalizations.of(
            context,
          )!.stepErrorInvalid,
        };
        _loading = false;
      });
      return;
    }
    final json = result.json!;
    final steps = json['steps'] as List;
    if (!mounted) return;
    setState(() {
      _steps = steps;
      _warnings = json['warnings'] ?? [];
      _loading = false;
      _maxVisitedStep = 1;
      _sessionStartedAt = DateTime.now();
      _stepStartedAt = DateTime.now();
      _stepDurations = List<int>.filled(steps.length, 0);
    });
    _updateIncidentProgress(includeTiming: true);
    _checkScrollable();
    // Speak the first step only if the tts_enabled pref is already known.
    // If it hasn't loaded yet, initState's callback will speak once it resolves.
    if (_ttsKnown && _ttsEnabled) {
      _narrating = true;
      _narrationStartedAt = DateTime.now();
      TtsService.instance.speak(
        widget.emergencyId,
        steps[0]['step'] as int,
        TtsService.langCodeFor(_loadedLocale ?? 'en'),
      );
    }
    // If Free Mode is on and nothing is narrating (TTS off), open the mic now
    // that the steps are loaded. Otherwise onComplete opens it post-narration.
    _maybeStartHandsFree();
  }

  void _nextStep() async {
    if (_currentStep < _steps.length - 1) {
      _recordCurrentStepDuration();
      setState(() {
        _currentStep++;
        _maxVisitedStep = _maxVisitedStep < _currentStep + 1
            ? _currentStep + 1
            : _maxVisitedStep;
        _stepStartedAt = DateTime.now();
      });
      _updateIncidentProgress(includeTiming: true);
      _cardScrollController.jumpTo(0);
      _checkScrollable();
      _speakCurrentStep();
    } else {
      _recordCurrentStepDuration();
      final endedAt = DateTime.now();
      setState(() {
        _completed = true;
        _maxVisitedStep = _steps.length;
        _sessionEndedAt = endedAt;
        _stepStartedAt = null;
      });
      _updateIncidentProgress(
        isCompleted: true,
        includeTiming: true,
        markEnded: true,
      );
      if (_ttsEnabled) TtsService.instance.stop();
      await _stopHandsFreeListening();
      if (mounted) setState(() => _handsFreeEnabled = false);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _recordCurrentStepDuration();
      setState(() {
        _currentStep--;
        _stepStartedAt = DateTime.now();
      });
      _updateIncidentProgress(includeTiming: true);
      _cardScrollController.jumpTo(0);
      _checkScrollable();
      _speakCurrentStep();
    }
  }
  void _resetProtocol() {
    final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return AlertDialog(
        backgroundColor: cs.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Row(
          children: [
            Icon(Icons.restart_alt, color: widget.emergencyColor),
            const SizedBox(width: 10),
            Expanded(child: Text(l10n.stepRestartTitle)),
          ],
        ),
        content: Text(l10n.stepRestartBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.settingsCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _recordCurrentStepDuration();
              setState(() {
                _currentStep = 0;
                _maxVisitedStep = 1;
                _sessionStartedAt = DateTime.now();
                _sessionEndedAt = null;
                _stepStartedAt = DateTime.now();
                _stepDurations = List<int>.filled(_steps.length, 0);
                _completed = false;
                // Restart re-honors the global Free Mode setting (like opening
                // the protocol fresh) instead of permanently disabling it.
                _handsFreeEnabled = _freeModeDefault;
                _handsFreeListening = false;
                _narrating = false;
              });
              _handsFree.cancel();
              _cardScrollController.jumpTo(0);
              _checkScrollable();
              _updateIncidentProgress(includeTiming: true);
              _speakCurrentStep();
            },
            style: TextButton.styleFrom(
              foregroundColor: widget.emergencyColor,
            ),
            child: Text(
          l10n.stepRestartConfirm,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
          ),
        ],
      );
    },
  );
}

  Future<void> _toggleHandsFree() async {
  if (_handsFreeEnabled) {
    await _stopHandsFreeListening();
    setState(() => _handsFreeEnabled = false);
  } else {
    setState(() => _handsFreeEnabled = true);
    await _startHandsFreeListening();
  }
}

/// Opens the mic for Free Mode only when appropriate: Free Mode on, protocol
/// loaded, not completed, and nothing currently narrating. While a step is
/// being read aloud, Free Mode stays in a "ready" state and the mic stays
/// closed — the onComplete handler opens it once the audio finishes.
void _maybeStartHandsFree() {
  if (!_handsFreeEnabled || _completed || _narrating || _steps.isEmpty) return;
  _startHandsFreeListening();
}

Future<void> _startHandsFreeListening() async {
  if (_completed || !_handsFreeEnabled || _narrating) return;
  // Only one start sequence at a time, so the several restart paths can't
  // stomp on each other mid-init.
  if (_handsFreeStarting) return;
  _handsFreeStarting = true;
  try {
  if (!_handsFreeReady) {
    final available = await _handsFree.initialize(
      onStatus: (status) {
      if (!mounted) return;
      final listening = status == SpeechToText.listeningStatus;
      if (_handsFreeListening != listening) {
        setState(() => _handsFreeListening = listening);
      }
      // speech_to_text is single-shot on iOS: each session ends after a
      // final result or pauseFor/listenFor elapses. Re-arm whenever a
      // session ends so hands-free stays active across step transitions.
      if (!listening && _handsFreeEnabled && !_completed && !_narrating) {
        Future.delayed(
          const Duration(milliseconds: 400),
          _startHandsFreeListening,
        );
      }
    },
      onError: (error) {
        if (!mounted) return;
        // A silence/no-match timeout is normal in hands-free mode (the user
        // simply hasn't spoken yet). iOS reports it as "permanent", but it is
        // NOT a real failure — keep the engine alive and re-arm so Free Mode
        // stays usable instead of dying after the audio finishes.
        if (isTransientSpeechError(error.errorMsg)) {
          Future.delayed(const Duration(seconds: 1), _maybeStartHandsFree);
          return;
        }
        if (error.permanent) setState(() => _handsFreeReady = false);
        if (_handsFreeEnabled && !error.permanent) {
          Future.delayed(const Duration(seconds: 1), _maybeStartHandsFree);
        }
      },
    );
    if (!mounted) return;
    _handsFreeReady = available;
    if (!available) {
      setState(() => _handsFreeEnabled = false);
      return;
    }
  }

  // Ensure any prior session is fully torn down before re-listening. The
  // plugin's isListening can lag and calling listen() twice throws on iOS.
  if (_handsFree.isListening) {
    await _handsFree.stop();
    await Future.delayed(const Duration(milliseconds: 150));
  }
  if (!mounted || _completed || !_handsFreeEnabled || _narrating) return;

  final localeCode = _loadedLocale ?? 'en';
  final localeId = switch (localeCode) {
    'he' => 'he_IL',
    'ar' => 'ar_SA',
    _    => 'en_US',
  };

  // Fresh session: allow one command to act (covers partial-then-final).
  _commandActedThisSession = false;
  await _handsFree.listen(
    onResult: _onHandsFreeResult,
    listenOptions: SpeechListenOptions(
      cancelOnError: false,
      partialResults: true,
      listenMode: ListenMode.dictation,
      localeId: localeId,
      // Commands act on the first matching partial, so these only govern the
      // idle/silence path. Keep pauseFor short for snappy finalization; the
      // watchdog re-arms whenever the session ends.
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2),
    ),
  );
  if (mounted) setState(() => _handsFreeListening = true);
  } catch (_) {
    // Recognizer busy/transient right after a session ended — retry shortly so
    // Free Mode recovers instead of silently going dead.
    if (mounted && _handsFreeEnabled && !_completed && !_narrating) {
      Future.delayed(const Duration(milliseconds: 600), _maybeStartHandsFree);
    }
  } finally {
    _handsFreeStarting = false;
  }
}

Future<void> _stopHandsFreeListening() async {
  await _handsFree.stop();
  if (mounted) setState(() => _handsFreeListening = false);
}

void _onHandsFreeResult(SpeechRecognitionResult result) {
  if (_commandActedThisSession) return;
  // Act on PARTIAL results, not just the final one. iOS only finalizes after a
  // multi-second end-of-speech silence (pauseFor), which made commands feel
  // 5+ seconds slow. Since we match specific command keywords, the match
  // itself is a strong signal — acting on the first matching partial removes
  // that delay almost entirely. The per-session guard prevents double-firing.
  final words = normalizeForMatch(result.recognizedWords);
  if (words.isEmpty) return;

  final isNext = _nextWordsNorm.any((w) => fuzzyContains(words, w));
  final isPrev = _previousWordsNorm.any((w) => fuzzyContains(words, w));

  if (isNext) {
    _commandActedThisSession = true;
    _nextStep();
  } else if (isPrev) {
    _commandActedThisSession = true;
    _previousStep();
  }
  // Re-arming is handled centrally by the onStatus callback / watchdog when the
  // session ends.
}
  void _speakCurrentStep() {
    if (_ttsEnabled) {
      // Mute the mic for the duration of narration so the spoken instructions
      // aren't misheard as commands. The onComplete subscription re-opens it.
      _narrating = true;
      _narrationStartedAt = DateTime.now();
      if (_handsFreeEnabled) _stopHandsFreeListening();
      final step = _steps[_currentStep];
      TtsService.instance.speak(
        widget.emergencyId,
        step['step'] as int,
        TtsService.langCodeFor(_loadedLocale ?? 'en'),
      );
    } else {
      // No narration to wait on — keep listening continuously if enabled.
      _narrating = false;
      if (_handsFreeEnabled && !_completed) _startHandsFreeListening();
    }
  }

  void _recordCurrentStepDuration() {
    final startedAt = _stepStartedAt;
    if (startedAt == null || _stepDurations.isEmpty) return;
    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    if (elapsed <= 0) return;
    _stepDurations[_currentStep] += elapsed;
    _stepStartedAt = DateTime.now();
  }

  int _elapsedSessionSeconds() {
    final stepTotal = _stepDurations.fold<int>(
      0,
      (sum, seconds) => sum + seconds,
    );
    if (stepTotal > 0) return stepTotal;

    final startedAt = _sessionStartedAt;
    if (startedAt == null) return 0;
    final endedAt = _sessionEndedAt ?? DateTime.now();
    final baseElapsed = endedAt.difference(startedAt).inSeconds;
    return baseElapsed < 0 ? 0 : baseElapsed;
  }

  String _formatClockTime(DateTime time) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return useWesternDigits(intl.DateFormat.jm(locale).format(time.toLocal()));
  }

  Future<void> _updateIncidentProgress({
    bool isCompleted = false,
    bool includeTiming = false,
    bool markEnded = false,
  }) async {
    final logId = widget.incidentLogId;
    if (logId == null) return;

    final totalSteps = _steps.length;
    final completedSteps = totalSteps == 0 ? 0 : _maxVisitedStep;

    try {
      await DatabaseService.updateIncidentProgress(
        logId: logId,
        completedSteps: completedSteps,
        totalSteps: totalSteps,
        isCompleted: isCompleted && totalSteps > 0,
        elapsedSeconds: includeTiming ? _elapsedSessionSeconds() : null,
        stepDurations: includeTiming && _stepDurations.isNotEmpty
            ? List<int>.from(_stepDurations)
            : null,
        markEnded: markEnded,
      );
    } catch (_) {
      // Progress logging should never block the emergency instructions.
    }
  }

  @override
  void dispose() {
    if (!_completed) {
      _recordCurrentStepDuration();
      _updateIncidentProgress(
        isCompleted: false,
        includeTiming: true,
        markEnded: true,
      );
    }
    _ttsCompleteSub?.cancel();
    _handsFreeWatchdog?.cancel();
    _handsFree.cancel();
    _cardScrollController.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final cs = theme.colorScheme;

  return Scaffold(
    backgroundColor: cs.surface,
    appBar: AppBar(
      title: Text(
        widget.emergencyTitle,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: cs.surface,
      foregroundColor: cs.onSurface,
      elevation: 0,
      centerTitle: false,
      actions: [
        if (!_loading && !_completed && _steps.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: l10n.stepRestartTitle,
            onPressed: _resetProtocol,
          ),
        if (!_loading && !_completed && _steps.isNotEmpty)
          IconButton(
            icon: Icon(
              _handsFreeEnabled ? Icons.hearing : Icons.hearing_disabled,
              color: _handsFreeEnabled ? widget.emergencyColor : null,
            ),
            tooltip: _handsFreeEnabled ? l10n.stepHandsFreeOn : l10n.stepHandsFreeOff,
            onPressed: _toggleHandsFree,
          ),
        IconButton(
          icon: const Icon(Icons.location_on_outlined),
          tooltip: l10n.settingsShareLocation,
          // Fix #9: null disables the button while a share is in progress,
          // preventing double-tap from opening two GPS dialogs.
          onPressed: _locationSharing
              ? null
              : () async {
                  setState(() => _locationSharing = true);
                  try {
                    await ShareLocationSheet.show(
                      context,
                      accentColor: widget.emergencyColor,
                    );
                  } finally {
                    if (mounted) setState(() => _locationSharing = false);
                  }
                },
        ),
      ],
    ),
    body: _loading
        ? Center(
            child: CircularProgressIndicator(color: widget.emergencyColor),
          )
        : _errorMessage != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        : _completed
        ? _buildCompletedScreen(l10n)
        : _buildStepScreen(l10n),
  );
}

  Widget _buildStepScreen(AppLocalizations l10n) {
    final step = _steps[_currentStep];
    final totalSteps = _steps.length;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Progress indicator ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.stepProgress(_currentStep + 1, totalSteps),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              Text(
                '${((_currentStep + 1) / totalSteps * 100).round()}%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: widget.emergencyColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Progress bar ──
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / totalSteps,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(widget.emergencyColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 32),
          // ── Hands-free banner ──
          if (_handsFreeEnabled) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: widget.emergencyColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: widget.emergencyColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.mic, color: widget.emergencyColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    l10n.stepHandsFreeBanner,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: widget.emergencyColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_handsFreeListening)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.emergencyColor,
                      ),
                    ),
                ],
              ),
            ),
          ],


          // ── Step card ──
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          controller: _cardScrollController,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Step number circle
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: widget.emergencyColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${_currentStep + 1}',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  child: Image.asset(
                                    step['image'] ??
                                        ProtocolLoader.stepImagePath(
                                          widget.emergencyId,
                                          _currentStep + 1,
                                        ),
                                    height: 240,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Step title — from JSON (not localized; JSON has its own language)
                              Text(
                                step['title'],
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: widget.emergencyColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),

                              // Step instruction — from JSON
                              Text(
                                step['instruction'],
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: cs.onSurface,
                                  fontSize: 17,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        // Fade overlay — signals more content below
                        if (_showScrollFade)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      cs.surfaceContainerLow.withValues(
                                        alpha: 0,
                                      ),
                                      cs.surfaceContainerLow,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Repeat button — pinned at the bottom of the card, never scrolls away.
                  // Routes through _speakCurrentStep (not TtsService.repeat) so it
                  // coordinates with Free Mode: mute the mic while re-reading, then
                  // reopen it when the audio finishes — repeatably.
                  IconButton(
                    onPressed: _ttsEnabled ? _speakCurrentStep : null,
                    icon: Icon(
                      Icons.replay_circle_filled,
                      color: _ttsEnabled
                          ? widget.emergencyColor
                          : cs.onSurfaceVariant.withValues(alpha: 0.3),
                      size: 28,
                    ),
                    tooltip: l10n.stepRepeatAudio,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Navigation buttons ──
          Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _previousStep,
                      icon: Icon(Icons.arrow_back, size: 20),
                      label: Text(l10n.stepPrevious),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: widget.emergencyColor,
                          width: 1.5,
                        ),
                        foregroundColor: widget.emergencyColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GradientButton(
                  height: 52,
                  gradientColors: [
                    widget.emergencyColor,
                    widget.emergencyColor.withValues(alpha: 0.85),
                  ],
                  onTap: _nextStep,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep == totalSteps - 1
                            ? l10n.stepDone
                            : l10n.stepNext,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentStep == totalSteps - 1
                            ? Icons.check
                            : Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Warnings bar ──
          if (_warnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showWarningsDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: cs.secondary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.stepWarningsBtn,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.secondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    // Chevron flips in RTL
                    Icon(
                      isRtl ? Icons.chevron_left : Icons.chevron_right,
                      color: cs.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedScreen(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final startedAt = _sessionStartedAt;
    final endedAt = _sessionEndedAt;
    final hasTiming = startedAt != null && endedAt != null;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 64).clamp(
                  0.0,
                  double.infinity,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Success icon ──
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: cs.tertiary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: cs.tertiary,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    l10n.stepCompleteTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.stepCompleteBody(widget.emergencyTitle),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  if (hasTiming) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.stepCompleteTimingTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildTimingRow(
                            icon: Icons.timer_outlined,
                            label: l10n.stepCompleteTotalTime,
                            value: formatLocalizedDuration(
                              context,
                              _elapsedSessionSeconds(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildTimingRow(
                            icon: Icons.play_circle_outline,
                            label: l10n.stepCompleteStartedAt,
                            value: _formatClockTime(startedAt),
                          ),
                          const SizedBox(height: 10),
                          _buildTimingRow(
                            icon: Icons.check_circle_outline,
                            label: l10n.stepCompleteFinishedAt,
                            value: _formatClockTime(endedAt),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Monitor vitals ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.stepCompleteVitalsTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.stepCompleteVitalsBody,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.tertiary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.history, color: cs.tertiary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.stepCompleteIncidentLogHint,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Disclaimer ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: cs.outline, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.stepCompleteDisclaimer,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Back to Home ──
                  GradientButton(
                    width: double.infinity,
                    height: 56,
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home, color: cs.onPrimary, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          l10n.stepCompleteBackBtn,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimingRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: cs.tertiary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  void _showWarningsDialog() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        final dialogCs = Theme.of(context).colorScheme;
        return Dialog(
          backgroundColor: dialogCs.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.stepWarningsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 20),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _warnings
                          .map(
                            (w) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: dialogCs.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.do_not_disturb,
                                    color: dialogCs.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      w,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(color: dialogCs.onSurface),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: cs.primary),
                    child: Text(
                      l10n.stepWarningsGotIt,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

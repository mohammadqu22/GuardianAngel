import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:guardian_angel/l10n/app_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';
import '../core/duration_formatting.dart';
import '../core/number_formatting.dart';
import '../widgets/gradient_button.dart';
import '../services/database_service.dart';
import '../services/tts_service.dart';

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
      final enabled = prefs.getBool('tts_enabled') ?? true;
      setState(() {
        _ttsEnabled = enabled;
        _ttsKnown = true;
      });
      // If the protocol finished loading before the pref was known,
      // speak the first step now. Otherwise _loadProtocol handles it.
      if (enabled && _steps.isNotEmpty) {
        TtsService.instance.speak(
          widget.emergencyId,
          _steps[0]['step'] as int,
          _ttsLangCode(_loadedLocale ?? 'en'),
        );
      }
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

    String? data;

    // 1. Try the locale-specific file (he/ or ar/ subdirectory)
    if (localeCode != 'en') {
      try {
        data = await rootBundle.loadString(
          'assets/data/$localeCode/${widget.emergencyId}.json',
        );
      } catch (_) {
        // locale file missing — will fall back to English below
      }
    }

    // 2. Fall back to the English file in assets/data/
    try {
      data ??= await rootBundle.loadString(
        'assets/data/${widget.emergencyId}.json',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.stepErrorFailed;
        _loading = false;
      });
      return;
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.stepErrorInvalid;
        _loading = false;
      });
      return;
    }
    final steps = json['steps'];
    if (!mounted) return;
    if (steps == null || (steps as List).isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.stepErrorInvalid;
        _loading = false;
      });
      return;
    }
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
      TtsService.instance.speak(
        widget.emergencyId,
        steps[0]['step'] as int,
        _ttsLangCode(_loadedLocale ?? 'en'),
      );
    }
  }

  void _nextStep() {
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

  void _speakCurrentStep() {
    if (_ttsEnabled) {
      final step = _steps[_currentStep];
      TtsService.instance.speak(
        widget.emergencyId,
        step['step'] as int,
        _ttsLangCode(_loadedLocale ?? 'en'),
      );
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

  static String _ttsLangCode(String locale) {
    switch (locale) {
      case 'ar':
        return 'ar-SA';
      case 'he':
        return 'he-IL';
      default:
        return 'en-US';
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
                                        'assets/images/${widget.emergencyId}/step_${_currentStep + 1}.png',
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
                  // Repeat button — pinned at the bottom of the card, never scrolls away
                  IconButton(
                    onPressed: _ttsEnabled
                        ? () => TtsService.instance.repeat()
                        : null,
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
                minHeight: constraints.maxHeight - 64,
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

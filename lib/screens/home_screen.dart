import 'package:flutter/material.dart';
import 'package:guardian_angel/l10n/app_localizations.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'learning_lesson_screen.dart';
import 'nearby_medical_screen.dart';
import 'step_screen.dart';
import 'settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';
import '../core/text_normalization.dart';
import '../services/database_service.dart';
import '../services/phone_service.dart';
import 'dart:async';
import '../services/ai_service.dart';
import '../services/quiz_generator.dart';
import '../widgets/protocol_icon.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onThemeModeChanged,
    required this.onLocaleChanged,
  });

  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _gridController = ScrollController();
  final SpeechToText _speech = SpeechToText();

  String _searchQuery = '';
  Locale? _lastLocale;

  // Learning Mode: false = Emergency (default), true = Learn.
  bool _learnMode = false;
  Map<String, Map<String, dynamic>> _learningProgress = {};

  // The header card (learn summary / nearby medical help) tracks the scroll
  // gesture: its height/opacity fraction (1 = fully shown) follows the finger
  // over ~_summaryCollapseRange px and snaps to the nearest end when the
  // scroll settles. The SOS button does a simpler shrink in emergency mode.
  static const double _summaryCollapseRange = 110;
  late final AnimationController _summaryController;
  bool _callButtonCompact = false;

  // While the search field has focus every other control goes inert: the
  // first tap anywhere else only dismisses the keyboard.
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _summaryController = AnimationController(
      vsync: this,
      value: 1.0,
      duration: const Duration(milliseconds: 200),
    );
    _searchFocus.addListener(() {
      if (mounted && _searchFocused != _searchFocus.hasFocus) {
        setState(() => _searchFocused = _searchFocus.hasFocus);
      }
      // Focusing the search field is a meaningful interaction — cancel the
      // idle voice prompt.
      if (_searchFocus.hasFocus) _consumeAutoPrompt();
    });
  }

  void _unfocusSearch() {
    if (_searchFocus.hasFocus) _searchFocus.unfocus();
  }

  /// Blocks taps on [child] while the search field has focus, letting them
  /// bubble to the screen-level GestureDetector that dismisses the keyboard.
  Widget _inertWhileSearching(Widget child) =>
      AbsorbPointer(absorbing: _searchFocused, child: child);

  // Scroll-affordance fades for the emergency grid: the bottom fade hints that
  // more protocols lie below, the top fade appears once the user scrolls down.
  bool _gridScrolledFromTop = false;
  bool _gridAtBottom = false;

  // Voice-search state.
  bool _speechReady = false;
  bool _speechInitializing = false;
  bool _isListening = false;
  // Intent flag: true while the user (or the auto-prompt) wants dictation to
  // stay open, so a silence timeout re-arms the mic instead of erroring out.
  bool _wantListening = false;
  List<LocaleName> _speechLocales = const [];

  Timer? _autoPromptTimer;
  bool _autoPromptVisible = false;
  // Set once the user meaningfully interacts (tap, navigation, field focus).
  // After that the idle voice prompt no longer auto-opens. Scrolling does NOT
  // set this.
  bool _autoPromptConsumed = false;
  // ── AI detection state ──
  Timer? _aiDebounceTimer;
  // Last query actually sent to the AI, so an identical follow-up (e.g. a
  // dictation final result matching the partial) isn't detected twice.
  String? _lastAiQuery;
  String? _aiSuggestedId;
  String? _aiSuggestedTitle;
  Color? _aiSuggestedColor;
  bool _aiLoading = false;

  /// Built inside build() so titles are always in the active locale.
  ///
  /// Language-independent keywords let direct phrases ("someone is choking")
  /// resolve to a protocol locally — without a Groq call — even when the active
  /// UI language differs from the typed text. They are matched as whole words /
  /// phrases (see [fuzzyContains]), never as substrings. Indirect descriptions
  /// ("someone can't breathe") intentionally have no keyword so they fall
  /// through to the AI fallback.
  List<Map<String, dynamic>> _buildEmergencyList(AppLocalizations l10n) => [
    {
      'id': 'choking',
      'title': l10n.emergencyChoking,
      'color': AppColors.chokingBlue,
      'keywords': const ['choking', 'choke'],
    },
    {
      'id': 'choking_infant',
      'title': l10n.emergencyChokingInfant,
      'color': AppColors.chokingBlue,
      'keywords': const [
        'infant choking',
        'baby choking',
        'choking infant',
        'choking baby',
      ],
    },
    {
      'id': 'cpr',
      'title': l10n.emergencyCPR,
      'color': AppColors.cprRed,
      'keywords': const ['cpr', 'cardiac arrest', 'resuscitation'],
    },
    {
      'id': 'cpr_infant',
      'title': l10n.emergencyCPRInfant,
      'color': AppColors.cprRed,
      'keywords': const ['infant cpr', 'baby cpr', 'cpr infant', 'cpr baby'],
    },
    {
      'id': 'burns',
      'title': l10n.emergencyBurns,
      'color': AppColors.burnOrange,
      'keywords': const ['burn', 'burns', 'burned', 'scald'],
    },
    {
      'id': 'bleeding',
      'title': l10n.emergencyBleeding,
      'color': AppColors.bleedingCrimson,
      'keywords': const ['bleeding', 'bleed', 'blood', 'hemorrhage'],
    },
    {
      'id': 'fractures',
      'title': l10n.emergencyFractures,
      'color': AppColors.fracturePurple,
      'keywords': const ['fracture', 'fractures', 'broken bone', 'broke'],
    },
    {
      'id': 'seizures',
      'title': l10n.emergencySeizures,
      'color': AppColors.seizureAmber,
      'keywords': const ['seizure', 'seizures', 'convulsion', 'epilepsy'],
    },
  ];

  /// Local-first protocol search shared by the grid and the AI-fallback gate.
  ///
  /// A protocol matches when the typed text overlaps its localized title in
  /// either direction (so both partial typing — "cho" → "Choking" — and full
  /// phrases — "someone is choking" → "Choking" — work) or contains one of its
  /// language-independent [keywords] as a whole word. Returns the full list for
  /// an empty query.
  List<Map<String, dynamic>> _filterEmergencies(
    List<Map<String, dynamic>> all,
    String rawQuery,
  ) {
    final query = _normalizeForSearch(rawQuery);
    if (query.isEmpty) return all;
    return all.where((e) {
      final title = _normalizeForSearch(e['title'] as String);
      // Partial typing of the title, or the title appearing within the phrase.
      if (title.contains(query) || fuzzyContains(query, title)) return true;
      final keywords = (e['keywords'] as List<String>?) ?? const [];
      return keywords.any(
        (kw) => fuzzyContains(query, _normalizeForSearch(kw)),
      );
    }).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_lastLocale != null && _lastLocale != locale) {
      _searchController.clear();
      _searchQuery = '';
      _resetGridScroll();
      if (_isListening) {
        _speech.stop();
        _isListening = false;
      }
      _cancelAutoPrompt();
    }
    // Start the timer only on the very first load
    if (_lastLocale == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final l10n = AppLocalizations.of(context);
        if (l10n != null) _startAutoPromptTimer(l10n);
      });
    }
    _lastLocale = locale;
  }

  @override
  void dispose() {
    _autoPromptTimer?.cancel();
    _aiDebounceTimer?.cancel();
    _speech.cancel();
    _gridController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  void _startAutoPromptTimer(AppLocalizations l10n) {
    _autoPromptTimer?.cancel();
    _autoPromptTimer = Timer(const Duration(seconds: 7), () async {
      // Only auto-open the mic when nothing meaningful has happened: not already
      // consumed by a tap/navigation/focus, not listening, no query typed, the
      // search field isn't focused, and the home screen is still the top route
      // (so it never fires over a pushed protocol/settings screen).
      if (!mounted ||
          _autoPromptConsumed ||
          _learnMode ||
          _isListening ||
          _searchQuery.isNotEmpty ||
          _searchFocus.hasFocus ||
          !(ModalRoute.of(context)?.isCurrent ?? true)) {
        return;
      }
      setState(() => _autoPromptVisible = true);
      await _toggleDictation(l10n);
    });
  }

  void _cancelAutoPrompt() {
    _autoPromptTimer?.cancel();
    _autoPromptTimer = null;
    if (_autoPromptVisible) {
      setState(() => _autoPromptVisible = false);
    }
  }

  /// Records a meaningful user interaction (tap, navigation, field focus) and
  /// permanently disables the idle voice prompt for this session — also stopping
  /// any prompt already in progress. Scrolling must NOT call this.
  void _consumeAutoPrompt() {
    if (_autoPromptConsumed) return;
    _autoPromptConsumed = true;
    _wantListening = false;
    // cancel() (not stop()) fully aborts the session and releases the shared iOS
    // recognizer, so a lingering home session can't time out and surface its
    // snackbar over a pushed protocol, and the protocol's Free Mode gets a clean
    // recognizer.
    _speech.cancel();
    _autoPromptTimer?.cancel();
    _autoPromptTimer = null;
    if (mounted && (_autoPromptVisible || _isListening)) {
      setState(() {
        _autoPromptVisible = false;
        _isListening = false;
      });
    }
  }

  // Explicit user dismissal of the voice prompt: also stop the mic and clear the
  // keep-listening intent so it doesn't re-arm.
  void _dismissVoicePrompt() {
    _wantListening = false;
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    }
    _cancelAutoPrompt();
  }

  /// Cancels any in-flight AI request and drops the current suggestion/spinner.
  void _clearAiSuggestion() {
    _aiDebounceTimer?.cancel();
    _lastAiQuery = null;
    if (_aiSuggestedId != null || _aiLoading) {
      setState(() {
        _aiSuggestedId = null;
        _aiSuggestedTitle = null;
        _aiSuggestedColor = null;
        _aiLoading = false;
      });
    }
  }

  void _runAiDetection(String query, AppLocalizations l10n) {
    _aiDebounceTimer?.cancel();

    // Local search is authoritative: if the typed text is too short, or it
    // already matches a protocol by title or keyword, never spend a Groq call
    // (or surface the AI card). The cloud fallback is only for indirect phrases
    // that local search can't resolve.
    final hasLocalMatch =
        query.trim().isNotEmpty &&
        _filterEmergencies(_buildEmergencyList(l10n), query).isNotEmpty;
    if (query.trim().length < 4 || hasLocalMatch) {
      _clearAiSuggestion();
      return;
    }

    // Skip if we've already detected this exact query (e.g. a dictation final
    // result identical to the partial that already triggered detection).
    if (query == _lastAiQuery) return;

    setState(() => _aiLoading = true);

    // fix: save query snapshot to guard against race conditions
    final requestQuery = query;
    _aiDebounceTimer = Timer(const Duration(milliseconds: 1500), () async {
      if (!mounted || requestQuery != _searchQuery) return;
      // Respect the AI-detection opt-out — this sends text off-device to Groq.
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('ai_detection_enabled') ?? true)) {
        if (mounted) setState(() => _aiLoading = false);
        return;
      }
      if (!mounted || requestQuery != _searchQuery) return;
      _lastAiQuery = requestQuery;
      final allEmergencies = _buildEmergencyList(l10n);
      final id = await AiService.detectEmergency(requestQuery);
      if (!mounted || requestQuery != _searchQuery) return;
      if (id == null) {
        // A no-match or transient failure shouldn't be cached, or re-typing the
        // same phrase would never re-query. Clear the dedupe key so it retries.
        _lastAiQuery = null;
        setState(() {
          _aiSuggestedId = null;
          _aiSuggestedTitle = null;
          _aiSuggestedColor = null;
          _aiLoading = false;
        });
        return;
      }
      final match = allEmergencies.firstWhere(
        (e) => e['id'] == id,
        orElse: () => {},
      );
      if (match.isEmpty) {
        setState(() {
          _aiSuggestedId = null;
          _aiLoading = false;
        });
        return;
      }
      setState(() {
        _aiSuggestedId = id;
        _aiSuggestedTitle = match['title'] as String;
        _aiSuggestedColor = match['color'] as Color;
        _aiLoading = false;
      });
    });
  }

  /// Normalizes text for locale-tolerant search matching. Speech recognition
  /// (especially Arabic/Hebrew) can add vowel diacritics, tatweel, or
  /// bidirectional control characters and use different letter forms, so the
  /// raw dictated string may not literally equal the stored title. Stripping
  /// those and unifying common letter variants lets matches succeed.
  static String _normalizeForSearch(String input) => normalizeForMatch(input);

  void _setSearchQuery(String value, {bool runAiDetection = true}) {
    _cancelAutoPrompt();
    setState(() {
      _searchQuery = value;
      _resetGridScroll();
    });
    // Only run AI emergency detection in emergency mode — learn-mode searches
    // are lesson queries and must not be sent off-device to Groq.
    if (runAiDetection && !_learnMode) {
      _runAiDetection(value, AppLocalizations.of(context)!);
    }
  }

  void _resetGridScroll() {
    _gridScrolledFromTop = false;
    _gridAtBottom = false;
    _summaryController.value = 1.0;
    _callButtonCompact = false;
    if (!_gridController.hasClients) return;
    _gridController.jumpTo(0);
  }

  /// Lazily initializes the speech engine the first time the mic is tapped.
  /// Returns whether recognition is usable. Permission prompts and missing
  /// engines are reported via a snackbar so typing always stays available.
  Future<bool> _ensureSpeechReady(AppLocalizations l10n) async {
    if (_speechReady) return true;
    if (_speechInitializing) return false;

    setState(() => _speechInitializing = true);
    try {
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: (error) => _onSpeechError(error, l10n),
      );
      final locales = available ? await _speech.locales() : <LocaleName>[];

      if (!mounted) return false;
      setState(() {
        _speechReady = available;
        _speechLocales = locales;
      });

      if (!available) _showSnackBar(l10n.homeDictationUnavailable);
      return available;
    } catch (_) {
      if (mounted) _showSnackBar(l10n.homeDictationUnavailable);
      return false;
    } finally {
      if (mounted) setState(() => _speechInitializing = false);
    }
  }

  Future<void> _toggleDictation(AppLocalizations l10n) async {
    if (_isListening) {
      _wantListening = false;
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    if (!await _ensureSpeechReady(l10n) || !mounted) return;

    _wantListening = true;
    await _beginListening(l10n);
  }

  /// Opens a recognition session. Shared by the initial mic tap/auto-prompt and
  /// the silence-timeout re-arm so listen options stay in one place.
  Future<void> _beginListening(AppLocalizations l10n) async {
    if (!mounted) return;
    await _speech.listen(
      onResult: _onSpeechResult,
      listenOptions: SpeechListenOptions(
        // We re-arm on transient errors ourselves, so don't let the plugin
        // tear the engine down on a silence timeout.
        cancelOnError: false,
        partialResults: true,
        listenMode: ListenMode.search,
        localeId: _localeIdFor(Localizations.localeOf(context)),
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
      ),
    );
    if (mounted) setState(() => _isListening = true);
  }

  /// Re-opens the mic after a silence/no-match timeout so dictation keeps
  /// waiting for the user to speak instead of surfacing a false error.
  Future<void> _restartListening(AppLocalizations l10n) async {
    // Let the previous session fully tear down before re-listening.
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted ||
        !_wantListening ||
        !_speechReady ||
        _isListening ||
        _searchQuery.isNotEmpty) {
      return;
    }
    await _beginListening(l10n);
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.trim();
    if (words.isEmpty) return;
    _searchController.value = TextEditingValue(
      text: words,
      selection: TextSelection.collapsed(offset: words.length),
    );
    // We have speech now — stop re-arming. Only run AI detection on the final
    // result so streaming partials don't fire duplicate requests.
    if (result.finalResult) _wantListening = false;
    _setSearchQuery(words, runAiDetection: result.finalResult);
  }

  void _onSpeechStatus(String status) {
    final listening = status == SpeechToText.listeningStatus;
    if (mounted && _isListening != listening) {
      setState(() => _isListening = listening);
    }
  }

  void _onSpeechError(SpeechRecognitionError error, AppLocalizations l10n) {
    if (!mounted) return;
    final isSilenceTimeout = isTransientSpeechError(error.errorMsg);

    // A silence/no-match timeout is NEVER a device failure — never show the
    // "unavailable" snackbar or tear down the engine for it. (This also fires
    // when a stopped/lingering session times out after the user has navigated
    // away, which previously surfaced the snackbar over a pushed protocol.)
    if (isSilenceTimeout) {
      setState(() => _isListening = false);
      // Only keep waiting if dictation is still wanted and nothing is captured.
      if (_wantListening && _searchQuery.isEmpty) {
        _restartListening(l10n);
      }
      return;
    }

    _wantListening = false;
    setState(() {
      _isListening = false;
      if (error.permanent) _speechReady = false;
    });
    if (error.permanent) _showSnackBar(l10n.homeDictationUnavailable);
  }

  /// Maps the active app locale to the closest available recognizer locale,
  /// falling back to a sensible default code when none is installed.
  String? _localeIdFor(Locale locale) {
    final preferred = switch (locale.languageCode) {
      'he' => const ['he_IL', 'he-IL', 'he'],
      'ar' => const ['ar_SA', 'ar-SA', 'ar'],
      _ => const ['en_US', 'en-US', 'en'],
    };

    for (final id in preferred) {
      if (_speechLocales.any((l) => l.localeId == id)) return id;
    }
    for (final l in _speechLocales) {
      if (l.localeId.split(RegExp('[-_]')).first == locale.languageCode) {
        return l.localeId;
      }
    }
    return preferred.first;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openEmergency({
    required String id,
    required String title,
    required Color color,
  }) async {
    int? incidentLogId;
    try {
      incidentLogId = await DatabaseService.logIncident(id);
    } catch (_) {
      // Logging is helpful, but the emergency flow must always remain available.
    }

    if (!mounted) return;
    _consumeAutoPrompt();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StepScreen(
          emergencyId: id,
          emergencyTitle: title,
          emergencyColor: color,
          incidentLogId: incidentLogId,
        ),
      ),
    );
  }

  void _openNearbyMedicalHelp() {
    _consumeAutoPrompt();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NearbyMedicalScreen()),
    );
  }

  Future<void> _refreshLearningProgress() async {
    try {
      final progress = await DatabaseService.getAllLearningProgress();
      if (mounted) setState(() => _learningProgress = progress);
    } catch (_) {
      // Progress is a nicety — the learning list works without it.
    }
  }

  void _setLearnMode(bool learn) {
    if (_learnMode == learn) return;
    setState(() {
      _learnMode = learn;
      _resetGridScroll();
    });
    if (learn) _refreshLearningProgress();
  }

  Future<void> _openLesson({
    required String id,
    required String title,
    required Color color,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LearningLessonScreen(
          emergencyId: id,
          emergencyTitle: title,
          emergencyColor: color,
        ),
      ),
    );
    if (mounted) _refreshLearningProgress();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final allEmergencies = _buildEmergencyList(l10n);
    final filteredEmergencies = _filterEmergencies(
      allEmergencies,
      _searchQuery,
    );

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        // Screen-level tap catcher: while the search field has focus, any tap
        // outside it (empty space or an inert control) dismisses the keyboard.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _unfocusSearch,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                SizedBox(
                  height: 68,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/branding/guardian_angel_logo_concept.png',
                            height: 64,
                            semanticLabel: l10n.appName,
                          ),
                        ],
                      ),
                      // Settings icon
                      Align(
                        alignment: AlignmentDirectional.topEnd,
                        child: _inertWhileSearching(
                          IconButton(
                            tooltip: l10n.homeSettingsTooltip,
                            onPressed: () {
                              _consumeAutoPrompt();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SettingsScreen(
                                    onThemeModeChanged:
                                        widget.onThemeModeChanged,
                                    onLocaleChanged: widget.onLocaleChanged,
                                  ),
                                ),
                              );
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: cs.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                              fixedSize: const Size(48, 48),
                            ),
                            icon: Icon(
                              Icons.settings_outlined,
                              color: cs.onSurface,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Mode switch: Emergency / Learn ──
                _inertWhileSearching(_buildModeSwitch(l10n)),
                const SizedBox(height: 12),

                // ── Section title ──
                Text(
                  _learnMode ? l10n.homeLearnTitle : l10n.homeSelectEmergency,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // ── Auto prompt banner (emergency mode only) ──
                if (!_learnMode)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _autoPromptVisible
                        ? GestureDetector(
                            onTap: _dismissVoicePrompt,
                            child: Container(
                              key: const ValueKey('prompt'),
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer.withValues(
                                  alpha: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                                border: Border.all(
                                  color: cs.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.mic, color: cs.primary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      l10n.homeAutoPrompt,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: cs.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.close,
                                    color: cs.primary,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),

                // ── Search Bar ──
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: _setSearchQuery,
                  decoration: InputDecoration(
                    hintText: _learnMode
                        ? l10n.homeSearchHintLearn
                        : l10n.homeSearchHint,
                    prefixIcon: Icon(Icons.search, color: cs.outline),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).deleteButtonTooltip,
                            icon: Icon(Icons.clear, color: cs.outline),
                            onPressed: () {
                              _searchController.clear();
                              _setSearchQuery('');
                            },
                          ),
                        IconButton(
                          tooltip: _isListening
                              ? l10n.homeDictationStopTooltip
                              : l10n.homeDictationStartTooltip,
                          onPressed: _speechInitializing
                              ? null
                              : () => _toggleDictation(l10n),
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? cs.primary : cs.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                // Both header cards (learn summary / nearby medical help)
                // collapse in sync with grid scrolling so the protocols get
                // the vertical space while browsing.
                ClipRect(
                  child: AnimatedBuilder(
                    animation: _summaryController,
                    builder: (context, child) => Align(
                      alignment: Alignment.topCenter,
                      heightFactor: _summaryController.value,
                      child: Opacity(
                        opacity: _summaryController.value,
                        child: child,
                      ),
                    ),
                    child: _learnMode
                        ? _buildLearningSummary(l10n, allEmergencies)
                        : _inertWhileSearching(
                            _buildNearbyMedicalButton(context),
                          ),
                  ),
                ),
                const SizedBox(height: 18),

                // ── Scrollable grid or "No results" ──
                Expanded(
                  child: _inertWhileSearching(
                    filteredEmergencies.isEmpty
                        ? (_aiSuggestedId != null || _aiLoading)
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_aiLoading) ...[
                                        CircularProgressIndicator(
                                          color: cs.primary,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          l10n.homeAiAnalyzing,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                color: cs.onSurfaceVariant,
                                              ),
                                        ),
                                      ] else if (_aiSuggestedId != null) ...[
                                        GestureDetector(
                                          onTap: () {
                                            _openEmergency(
                                              id: _aiSuggestedId!,
                                              title: _aiSuggestedTitle!,
                                              color: _aiSuggestedColor!,
                                            );
                                            setState(() {
                                              _aiSuggestedId = null;
                                              _aiSuggestedTitle = null;
                                              _aiSuggestedColor = null;
                                            });
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(28),
                                            decoration: BoxDecoration(
                                              color: _aiSuggestedColor!
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadius.xl,
                                                  ),
                                              border: Border.all(
                                                color: _aiSuggestedColor!
                                                    .withValues(alpha: 0.4),
                                                width: 2,
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    20,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _aiSuggestedColor!
                                                        .withValues(
                                                          alpha: 0.12,
                                                        ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.auto_awesome,
                                                    color: _aiSuggestedColor,
                                                    size: 48,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                Text(
                                                  l10n.homeAiDetectedTitle,
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color:
                                                            cs.onSurfaceVariant,
                                                      ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  _aiSuggestedTitle!,
                                                  style: theme
                                                      .textTheme
                                                      .headlineMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            _aiSuggestedColor,
                                                      ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 24),
                                                Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _aiSuggestedColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          AppRadius.lg,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .play_arrow_rounded,
                                                        color: Colors.white,
                                                        size: 24,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        l10n.homeAiOpenProtocol,
                                                        style: theme
                                                            .textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: cs.outline,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        l10n.homeNoResults,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(color: cs.outline),
                                      ),
                                    ],
                                  ),
                                )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              const spacing = 16.0;
                              // When there are more than four protocols, shrink the
                              // cards enough that the next row peeks from below. That
                              // gives a clear cue that more protocols are available.
                              const peek = 44.0;
                              final hasOverflow =
                                  filteredEmergencies.length > 4;
                              final available =
                                  constraints.maxHeight -
                                  spacing -
                                  (hasOverflow ? spacing + peek : 0);
                              final cardHeight = available > 160
                                  ? available / 2
                                  : 80;
                              final showBottomFade =
                                  hasOverflow && !_gridAtBottom;

                              return NotificationListener<ScrollNotification>(
                                onNotification: _onGridScroll,
                                child: Stack(
                                  children: [
                                    GridView.builder(
                                      controller: _gridController,
                                      physics: const BouncingScrollPhysics(),
                                      padding: EdgeInsets.zero,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: spacing,
                                            mainAxisSpacing: spacing,
                                            mainAxisExtent: cardHeight
                                                .toDouble(),
                                          ),
                                      itemCount: filteredEmergencies.length,
                                      itemBuilder: (context, i) {
                                        final e = filteredEmergencies[i];
                                        final id = e['id'] as String;
                                        final title = e['title'] as String;
                                        final color = e['color'] as Color;
                                        return _learnMode
                                            ? _buildLearningCard(
                                                context,
                                                l10n: l10n,
                                                id: id,
                                                title: title,
                                                color: color,
                                              )
                                            : _buildEmergencyCard(
                                                context,
                                                id: id,
                                                title: title,
                                                color: color,
                                              );
                                      },
                                    ),
                                    _buildScrollFade(
                                      top: true,
                                      visible: _gridScrolledFromTop,
                                      color: cs.surface,
                                    ),
                                    _buildScrollFade(
                                      top: false,
                                      visible: showBottomFade,
                                      color: cs.surface,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ── SOS bottom bar (emergency mode only) ──
      bottomNavigationBar: _learnMode
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _unfocusSearch,
                child: _inertWhileSearching(_buildCallButton(context)),
              ),
            ),
    );
  }

  /// Keeps the edge fades in sync with the scroll position: the top fade shows
  /// once scrolled away from the top, the bottom fade hides at the very end.
  /// In learn mode it also collapses the summary card while scrolling down and
  /// brings it back on the first upward scroll.
  bool _onGridScroll(ScrollNotification notification) {
    final m = notification.metrics;
    final fromTop = m.pixels > 8;
    final atBottom = m.extentAfter == 0;

    // The bottom bounce of BouncingScrollPhysics produces upward deltas the
    // user never asked for — anything at/past the bottom edge is ignored so
    // the header/button only react to intentional scrolling.
    final inBottomOverscroll = m.pixels >= m.maxScrollExtent - 1;

    var callCompact = _callButtonCompact;
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (m.pixels <= 0) {
        // Pulled back to the very top — make sure the header is fully open.
        if (_summaryController.value < 1 && !_summaryController.isAnimating) {
          _summaryController.animateTo(1, curve: Curves.easeOut);
        }
        callCompact = false;
      } else if (!inBottomOverscroll && delta != 0) {
        // Track the gesture: the header card shrinks/grows proportionally to
        // how far the grid has been scrolled, not as an on/off jump.
        _summaryController.stop();
        _summaryController.value =
            (_summaryController.value - delta / _summaryCollapseRange).clamp(
              0.0,
              1.0,
            );
        if (!_learnMode) {
          if (delta < -1) callCompact = false;
          if (delta > 1) callCompact = true;
        }
      }
    } else if (notification is ScrollEndNotification) {
      // Don't rest half-collapsed: settle to whichever end is closer.
      final value = _summaryController.value;
      if (value > 0 && value < 1) {
        _summaryController.animateTo(
          value >= 0.5 ? 1 : 0,
          curve: Curves.easeOut,
        );
      }
    }

    if (fromTop != _gridScrolledFromTop ||
        atBottom != _gridAtBottom ||
        callCompact != _callButtonCompact) {
      setState(() {
        _gridScrolledFromTop = fromTop;
        _gridAtBottom = atBottom;
        _callButtonCompact = callCompact;
      });
    }
    return false;
  }

  /// A soft gradient that dissolves the grid edge into the background, signalling
  /// that content continues past the visible area. Theme-aware via [color].
  Widget _buildScrollFade({
    required bool top,
    required bool visible,
    required Color color,
  }) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: 0,
      right: 0,
      height: 52,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: visible ? 1 : 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: top ? Alignment.topCenter : Alignment.bottomCenter,
                end: top ? Alignment.bottomCenter : Alignment.topCenter,
                colors: [color, color.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      button: true,
      label: l10n.homeCallBtn,
      // Shrinks a little while the grid scrolls down so more protocols are
      // visible, and springs back on the first upward scroll. The horizontal
      // margin pulls the sides in so the whole button gets smaller, not just
      // its height.
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: _callButtonCompact ? 40 : 52,
        margin: _callButtonCompact
            ? const EdgeInsets.symmetric(horizontal: 32)
            : EdgeInsets.zero,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-0.97, -0.26),
              end: const Alignment(0.97, 0.26),
              colors: [cs.primary, cs.primaryContainer],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: cs.onSurface.withValues(alpha: 0.08),
                offset: const Offset(0, 10),
                blurRadius: 28,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: () {
                _consumeAutoPrompt();
                PhoneService.call(
                  '101',
                  context,
                  l10n.homeCallFailed,
                  duration: const Duration(seconds: 3),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone, color: cs.onPrimary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    l10n.homeCallBtn,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Compact single-line entry: kept slim so the protocol grid starts as high
  /// on the screen as possible — the destination screen explains itself.
  Widget _buildNearbyMedicalButton(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: _openNearbyMedicalHelp,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.tertiary.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.local_hospital_outlined,
                  color: AppColors.tertiary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.homeNearbyMedical,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Icon(
                isRtl ? Icons.chevron_left : Icons.chevron_right,
                color: cs.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSwitch(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<bool>(
        segments: [
          ButtonSegment(
            value: false,
            label: Text(l10n.homeModeEmergency),
            icon: const Icon(Icons.emergency_outlined, size: 18),
          ),
          ButtonSegment(
            value: true,
            label: Text(l10n.homeModeLearn),
            icon: const Icon(Icons.school_outlined, size: 18),
          ),
        ],
        selected: {_learnMode},
        onSelectionChanged: (selection) => _setLearnMode(selection.first),
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          backgroundColor: cs.surfaceContainerLow,
          foregroundColor: cs.onSurfaceVariant,
          selectedBackgroundColor: cs.primary,
          selectedForegroundColor: cs.onPrimary,
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.15)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }

  Widget _buildLearningSummary(
    AppLocalizations l10n,
    List<Map<String, dynamic>> allEmergencies,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final total = allEmergencies.length;
    final completed = allEmergencies
        .where((e) => _learningProgress[e['id']]?['is_completed'] == 1)
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.tertiary.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.school_outlined, color: AppColors.tertiary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.learnSummary(completed, total),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : completed / total,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.tertiary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningCard(
    BuildContext context, {
    required AppLocalizations l10n,
    required String id,
    required String title,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final progress = _learningProgress[id];
    final completed = progress != null && progress['is_completed'] == 1;
    final bestScore = progress?['best_score'] as int?;
    final quizTotal = progress?['quiz_total'] as int?;
    final hasScore = completed && bestScore != null && (quizTotal ?? 0) > 0;
    final medal = hasScore ? QuizMedal.of(bestScore, quizTotal!) : null;

    // An abandoned quiz run shows as in-progress until the protocol is
    // completed at least once; after that the completed badge wins.
    final partialAnswered = progress?['partial_answered'] as int?;
    final partialTotal = progress?['partial_total'] as int?;
    final inProgress =
        !completed && (partialAnswered ?? 0) > 0 && (partialTotal ?? 0) > 0;

    return GestureDetector(
      onTap: () => _openLesson(id: id, title: title, color: color),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: ProtocolIcon(emergencyId: id, color: color, size: 58),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      medal != null
                          ? Icons.workspace_premium
                          : completed
                          ? Icons.check_circle
                          : inProgress
                          ? Icons.timelapse
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: medal != null
                          ? medal.color
                          : (completed || inProgress)
                          ? color
                          : cs.outline,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      completed
                          ? l10n.learnCompleted
                          : inProgress
                          ? l10n.learnInProgress
                          : l10n.learnNotStarted,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: (completed || inProgress)
                            ? color
                            : cs.onSurfaceVariant,
                        fontWeight: (completed || inProgress)
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (hasScore) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.learnBestScore(bestScore, quizTotal!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ] else if (inProgress) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.learnAnswered(partialAnswered!, partialTotal!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(
    BuildContext context, {
    required String id,
    required String title,
    required Color color,
  }) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _openEmergency(id: id, title: title, color: color),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          // Accent-tinted edge ties each card to its emergency colour while
          // staying legible on both light and dark surfaces.
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
        ),
        // FittedBox keeps the card content from overflowing when the grid is
        // squeezed into a short space (small screens / compact test windows).
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: ProtocolIcon(emergencyId: id, color: color, size: 62),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

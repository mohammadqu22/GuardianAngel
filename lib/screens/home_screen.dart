import 'package:flutter/material.dart';
import 'package:guardian_angel/l10n/app_localizations.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'step_screen.dart';
import 'settings_screen.dart';
import '../core/app_theme.dart';
import '../services/database_service.dart';
import '../services/phone_service.dart';

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

class _HomeScreenState extends State<HomeScreen> {
  static const int _emergenciesPerPage = 4;

  final TextEditingController _searchController = TextEditingController();
  final SpeechToText _speech = SpeechToText();

  String _searchQuery = '';
  int _emergencyPage = 0;
  Locale? _lastLocale;

  // Voice-search state.
  bool _speechReady = false;
  bool _speechInitializing = false;
  bool _isListening = false;
  List<LocaleName> _speechLocales = const [];

  /// Built inside build() so titles are always in the active locale.
  List<Map<String, dynamic>> _buildEmergencyList(AppLocalizations l10n) => [
    {
      'id': 'choking',
      'title': l10n.emergencyChoking,
      'icon': Icons.air,
      'color': AppColors.chokingBlue,
    },
    {
      'id': 'choking_infant',
      'title': l10n.emergencyChokingInfant,
      'icon': Icons.baby_changing_station,
      'color': AppColors.chokingBlue,
    },
    {
      'id': 'cpr',
      'title': l10n.emergencyCPR,
      'icon': Icons.favorite,
      'color': AppColors.cprRed,
    },
    {
      'id': 'cpr_infant',
      'title': l10n.emergencyCPRInfant,
      'icon': Icons.monitor_heart,
      'color': AppColors.cprRed,
    },
    {
      'id': 'burns',
      'title': l10n.emergencyBurns,
      'icon': Icons.local_fire_department,
      'color': AppColors.burnOrange,
    },
    {
      'id': 'bleeding',
      'title': l10n.emergencyBleeding,
      'icon': Icons.water_drop,
      'color': AppColors.bleedingCrimson,
    },
    {
      'id': 'fractures',
      'title': l10n.emergencyFractures,
      'icon': Icons.healing,
      'color': AppColors.fracturePurple,
    },
    {
      'id': 'seizures',
      'title': l10n.emergencySeizures,
      'icon': Icons.warning_amber_rounded,
      'color': AppColors.seizureAmber,
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    // When the language is switched (e.g. from Settings), the emergency titles
    // change language, so a leftover search query no longer matches. Reset the
    // search so the user returns to a clean home screen in the new language.
    if (_lastLocale != null && _lastLocale != locale) {
      _searchController.clear();
      _searchQuery = '';
      _emergencyPage = 0;
      if (_isListening) {
        _speech.stop();
        _isListening = false;
      }
    }
    _lastLocale = locale;
  }

  @override
  void dispose() {
    _speech.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Normalizes text for locale-tolerant search matching. Speech recognition
  /// (especially Arabic/Hebrew) can add vowel diacritics, tatweel, or
  /// bidirectional control characters and use different letter forms, so the
  /// raw dictated string may not literally equal the stored title. Stripping
  /// those and unifying common letter variants lets matches succeed.
  static String _normalizeForSearch(String input) {
    final buffer = StringBuffer();
    for (var ch in input.runes) {
      // Arabic diacritics (tashkeel) and Hebrew niqqud / cantillation marks.
      if ((ch >= 0x0610 && ch <= 0x061A) ||
          (ch >= 0x064B && ch <= 0x065F) ||
          ch == 0x0670 ||
          (ch >= 0x06D6 && ch <= 0x06ED) ||
          ch == 0x0640 || // Arabic tatweel
          (ch >= 0x0591 && ch <= 0x05BD) ||
          ch == 0x05BF ||
          ch == 0x05C1 ||
          ch == 0x05C2 ||
          ch == 0x05C4 ||
          ch == 0x05C5 ||
          ch == 0x05C7) {
        continue;
      }
      // Bidirectional control characters.
      if (ch == 0x200E ||
          ch == 0x200F ||
          ch == 0x061C ||
          (ch >= 0x202A && ch <= 0x202E) ||
          (ch >= 0x2066 && ch <= 0x2069)) {
        continue;
      }
      // Unify Arabic alef variants (آ أ إ → ا) and alef-maqsura (ى → ي).
      if (ch == 0x0622 || ch == 0x0623 || ch == 0x0625) ch = 0x0627;
      if (ch == 0x0649) ch = 0x064A;
      buffer.writeCharCode(ch);
    }
    return buffer
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _setSearchQuery(String value) {
    setState(() {
      _searchQuery = value;
      _emergencyPage = 0;
    });
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
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    if (!await _ensureSpeechReady(l10n) || !mounted) return;

    await _speech.listen(
      onResult: _onSpeechResult,
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
        listenMode: ListenMode.search,
        localeId: _localeIdFor(Localizations.localeOf(context)),
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
      ),
    );

    if (mounted) setState(() => _isListening = true);
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.trim();
    if (words.isEmpty) return;
    _searchController.value = TextEditingValue(
      text: words,
      selection: TextSelection.collapsed(offset: words.length),
    );
    _setSearchQuery(words);
  }

  void _onSpeechStatus(String status) {
    final listening = status == SpeechToText.listeningStatus;
    if (mounted && _isListening != listening) {
      setState(() => _isListening = listening);
    }
  }

  void _onSpeechError(SpeechRecognitionError error, AppLocalizations l10n) {
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final allEmergencies = _buildEmergencyList(l10n);
    final query = _normalizeForSearch(_searchQuery);
    final filteredEmergencies = query.isEmpty
        ? allEmergencies
        : allEmergencies
              .where(
                (e) =>
                    _normalizeForSearch(e['title'] as String).contains(query),
              )
              .toList();
    final pageCount = filteredEmergencies.isEmpty
        ? 1
        : ((filteredEmergencies.length - 1) ~/ _emergenciesPerPage) + 1;
    final currentPage = _emergencyPage.clamp(0, pageCount - 1);
    final currentEmergencies = filteredEmergencies
        .skip(currentPage * _emergenciesPerPage)
        .take(_emergenciesPerPage)
        .toList();

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              SizedBox(
                height: 92,
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
                          height: 88,
                          semanticLabel: l10n.appName,
                        ),
                      ],
                    ),
                    // Settings icon
                    Align(
                      alignment: AlignmentDirectional.topEnd,
                      child: IconButton(
                        tooltip: l10n.homeSettingsTooltip,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsScreen(
                                onThemeModeChanged: widget.onThemeModeChanged,
                                onLocaleChanged: widget.onLocaleChanged,
                              ),
                            ),
                          );
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: cs.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
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
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Section title ──
              Text(l10n.homeSelectEmergency, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),

              // ── Search Bar ──
              TextField(
                controller: _searchController,
                onChanged: _setSearchQuery,
                decoration: InputDecoration(
                  hintText: l10n.homeSearchHint,
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
              const SizedBox(height: 20),

              // ── Grid or "No results" ──
              Expanded(
                child: filteredEmergencies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: cs.outline),
                            const SizedBox(height: 12),
                            Text(
                              l10n.homeNoResults,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: cs.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                const spacing = 16.0;
                                final cardWidth =
                                    (constraints.maxWidth - spacing) / 2;
                                final cardHeight =
                                    (constraints.maxHeight - spacing) / 2;

                                return GridView.count(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: spacing,
                                  mainAxisSpacing: spacing,
                                  childAspectRatio: cardWidth / cardHeight,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  children: currentEmergencies
                                      .map(
                                        (e) => _buildEmergencyCard(
                                          context,
                                          id: e['id'] as String,
                                          title: e['title'] as String,
                                          icon: e['icon'] as IconData,
                                          color: e['color'] as Color,
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildPageControls(
                            context,
                            currentPage: currentPage,
                            pageCount: pageCount,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),

      // ── SOS bottom bar ──
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 6, 20, 10),
        child: _buildCallButton(context),
      ),
    );
  }

  Widget _buildPageControls(
    BuildContext context, {
    required int currentPage,
    required int pageCount,
  }) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final canGoBack = currentPage > 0;
    final canGoForward = currentPage < pageCount - 1;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canGoBack
                ? () => setState(() => _emergencyPage = currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            label: Text(l10n.homePreviousPage),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            l10n.homePageIndicator(currentPage + 1, pageCount),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canGoForward
                ? () => setState(() => _emergencyPage = currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            label: Text(l10n.homeNextPage),
          ),
        ),
      ],
    );
  }

  Widget _buildCallButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      button: true,
      label: l10n.homeCallBtn,
      child: SizedBox(
        height: 52,
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
              onTap: () => PhoneService.call(
                '101',
                context,
                l10n.homeCallFailed,
                duration: const Duration(seconds: 3),
              ),
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

  Widget _buildEmergencyCard(
    BuildContext context, {
    required String id,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _openEmergency(id: id, title: title, color: color),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.15),
            width: 1,
          ),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 40, color: color),
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

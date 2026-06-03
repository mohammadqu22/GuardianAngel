import 'dart:async';
import 'package:flutter/material.dart';
import 'package:guardian_angel/l10n/app_localizations.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'nearby_medical_screen.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _gridController = ScrollController();
  final SpeechToText _speech = SpeechToText();

  String _searchQuery = '';
  Locale? _lastLocale;

  bool _gridScrolledFromTop = false;
  bool _gridAtBottom = false;

  bool _speechReady = false;
  bool _speechInitializing = false;
  bool _isListening = false;
  List<LocaleName> _speechLocales = const [];

  // ── Auto-prompt state ──
  Timer? _autoPromptTimer;
  bool _autoPromptVisible = false;

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
    _speech.cancel();
    _gridController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Auto-prompt methods ──

  void _startAutoPromptTimer(AppLocalizations l10n) {
    _autoPromptTimer?.cancel();
    _autoPromptTimer = Timer(const Duration(seconds: 7), () async {
      if (!mounted || _isListening || _searchQuery.isNotEmpty) return;
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

  // ── Search & normalization ──

  static String _normalizeForSearch(String input) {
    final buffer = StringBuffer();
    for (var ch in input.runes) {
      if ((ch >= 0x0610 && ch <= 0x061A) ||
          (ch >= 0x064B && ch <= 0x065F) ||
          ch == 0x0670 ||
          (ch >= 0x06D6 && ch <= 0x06ED) ||
          ch == 0x0640 ||
          (ch >= 0x0591 && ch <= 0x05BD) ||
          ch == 0x05BF ||
          ch == 0x05C1 ||
          ch == 0x05C2 ||
          ch == 0x05C4 ||
          ch == 0x05C5 ||
          ch == 0x05C7) {
        continue;
      }
      if (ch == 0x200E ||
          ch == 0x200F ||
          ch == 0x061C ||
          (ch >= 0x202A && ch <= 0x202E) ||
          (ch >= 0x2066 && ch <= 0x2069)) {
        continue;
      }
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
    _cancelAutoPrompt();
    setState(() {
      _searchQuery = value;
      _resetGridScroll();
    });
  }

  void _resetGridScroll() {
    _gridScrolledFromTop = false;
    _gridAtBottom = false;
    if (!_gridController.hasClients) return;
    _gridController.jumpTo(0);
  }

  // ── Speech ──

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
    _cancelAutoPrompt();
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Navigation ──

  Future<void> _openEmergency({
    required String id,
    required String title,
    required Color color,
  }) async {
    _cancelAutoPrompt();
    int? incidentLogId;
    try {
      incidentLogId = await DatabaseService.logIncident(id);
    } catch (_) {}

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

  void _openNearbyMedicalHelp() {
    _cancelAutoPrompt();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NearbyMedicalScreen()),
    );
  }

  // ── Build ──

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
              (e) => _normalizeForSearch(e['title'] as String).contains(query),
            )
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
                    Align(
                      alignment: AlignmentDirectional.topEnd,
                      child: IconButton(
                        tooltip: l10n.homeSettingsTooltip,
                        onPressed: () {
                          _cancelAutoPrompt();
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

              // ── Auto-prompt banner ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _autoPromptVisible
                    ? GestureDetector(
                        key: const ValueKey('prompt'),
                        onTap: _cancelAutoPrompt,
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
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
                                  'What is your emergency? Tap to dismiss.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(Icons.close, color: cs.primary, size: 18),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),

              // ── Search Bar ──
              TextField(
                controller: _searchController,
                onChanged: _setSearchQuery,
                onTap: _cancelAutoPrompt,
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
                            : () {
                                _cancelAutoPrompt();
                                _toggleDictation(l10n);
                              },
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
              _buildNearbyMedicalButton(context),
              const SizedBox(height: 18),

              // ── Scrollable grid or "No results" ──
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
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 16.0;
                          const peek = 44.0;
                          final hasOverflow = filteredEmergencies.length > 4;
                          final available =
                              constraints.maxHeight -
                              spacing -
                              (hasOverflow ? spacing + peek : 0);
                          final cardHeight = available > 160 ? available / 2 : 80;
                          final showBottomFade = hasOverflow && !_gridAtBottom;

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
                                        mainAxisExtent: cardHeight.toDouble(),
                                      ),
                                  itemCount: filteredEmergencies.length,
                                  itemBuilder: (context, i) {
                                    final e = filteredEmergencies[i];
                                    return _buildEmergencyCard(
                                      context,
                                      id: e['id'] as String,
                                      title: e['title'] as String,
                                      icon: e['icon'] as IconData,
                                      color: e['color'] as Color,
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

  bool _onGridScroll(ScrollNotification notification) {
    final m = notification.metrics;
    final fromTop = m.pixels > 8;
    final atBottom = m.extentAfter == 0;
    if (fromTop != _gridScrolledFromTop || atBottom != _gridAtBottom) {
      setState(() {
        _gridScrolledFromTop = fromTop;
        _gridAtBottom = atBottom;
      });
    }
    return false;
  }

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

  Widget _buildNearbyMedicalButton(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: _openNearbyMedicalHelp,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.local_hospital_outlined,
                  color: AppColors.tertiary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeNearbyMedical,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.homeNearbyMedicalSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.outline),
            ],
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
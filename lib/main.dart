import 'package:flutter/material.dart';
import 'package:guardian_angel/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/disclaimer_screen.dart';
import 'services/permission_service.dart';
import 'services/database_service.dart';
import 'services/tts_service.dart';
import 'core/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GuardianAngelApp());
}

class GuardianAngelApp extends StatefulWidget {
  const GuardianAngelApp({super.key});

  @override
  State<GuardianAngelApp> createState() => _GuardianAngelAppState();
}

class _GuardianAngelAppState extends State<GuardianAngelApp> {
  bool _loading = true;
  bool _showDisclaimer = true;
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Read SharedPreferences first so disclaimer/theme/locale are always set
    // correctly even if a later service initialisation throws.
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('disclaimer_accepted') ?? false;
    final themePref = prefs.getString('theme_mode') ?? 'system';
    // On first launch there is no stored preference — use the device language
    // if it is one of the three supported codes, otherwise fall back to English.
    final String langPref;
    if (prefs.containsKey('language')) {
      langPref = prefs.getString('language')!;
    } else {
      const supported = {'en', 'he', 'ar'};
      final deviceLang =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      langPref = supported.contains(deviceLang) ? deviceLang : 'en';
      await prefs.setString('language', langPref);
    }

    // Initialise services — failures must not prevent the UI from loading.
    try {
      await DatabaseService.database;
    } catch (_) {
      // DB unavailable; contacts/log features will be degraded.
    }
    try {
      await TtsService.instance.init();
    } catch (_) {
      // TTS unavailable; the app remains functional without audio.
    }

    if (mounted) {
      setState(() {
        _showDisclaimer = !accepted;
        _themeMode = themeModeFromString(themePref);
        _locale = _localeFromCode(langPref);
        _loading = false;
      });
    }
    PermissionService.requestAppPermissions();
  }

  static Locale _localeFromCode(String code) {
    switch (code) {
      case 'he':
        return const Locale('he');
      case 'ar':
        return const Locale('ar');
      default:
        return const Locale('en');
    }
  }

  void _onThemeModeChanged(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  void _onLocaleChanged(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guardian Angel',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: _themeMode,
      // ── Localization ──────────────────────────────────────────────────────
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // ─────────────────────────────────────────────────────────────────────
      home: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _showDisclaimer
          ? DisclaimerScreen(
              onThemeModeChanged: _onThemeModeChanged,
              onLocaleChanged: _onLocaleChanged,
            )
          : HomeScreen(
              onThemeModeChanged: _onThemeModeChanged,
              onLocaleChanged: _onLocaleChanged,
            ),
    );
  }
}

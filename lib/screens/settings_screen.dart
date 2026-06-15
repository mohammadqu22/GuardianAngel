import 'package:flutter/material.dart';
import 'package:guardian_angel/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../services/phone_service.dart';
import '../core/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/share_location_sheet.dart';
import '../widgets/source_item.dart';
import 'incident_log_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.onThemeModeChanged,
    required this.onLocaleChanged,
  });

  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Locale>    onLocaleChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Stored as a locale code: 'en', 'he', or 'ar'.
  String _selectedLocaleCode = 'en';
  bool      _ttsEnabled  = true;
  bool      _freeModeEnabled = true;
  bool      _aiDetectionEnabled = true;
  ThemeMode _themeMode   = ThemeMode.system;
  Map<String, dynamic>? _emergencyContact;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadEmergencyContact();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final raw = prefs.getString('language') ?? 'en';
    const validCodes = {'en', 'he', 'ar'};
    setState(() {
      _selectedLocaleCode = validCodes.contains(raw) ? raw : 'en';
      _ttsEnabled         = prefs.getBool('tts_enabled') ?? true;
      _freeModeEnabled    = prefs.getBool('free_mode_enabled') ?? true;
      _aiDetectionEnabled = prefs.getBool('ai_detection_enabled') ?? true;
      _themeMode          = themeModeFromString(prefs.getString('theme_mode') ?? 'system');
    });
  }

  String _themeModeLabel(AppLocalizations l10n, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return l10n.settingsThemeLight;
      case ThemeMode.dark:  return l10n.settingsThemeDark;
      default:              return l10n.settingsThemeSystem;
    }
  }

  /// Returns the language name in its own script — always shown natively so
  /// users can recognise their language regardless of the active locale.
  static String _nativeLanguageName(String code) {
    switch (code) {
      case 'he': return 'עברית';
      case 'ar': return 'العربية';
      default:   return 'English';
    }
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final String value;
    switch (mode) {
      case ThemeMode.light: value = 'light'; break;
      case ThemeMode.dark:  value = 'dark';  break;
      default:              value = 'system';
    }
    await prefs.setString('theme_mode', value);
    if (!mounted) return;
    setState(() => _themeMode = mode);
    widget.onThemeModeChanged(mode);
  }

  Future<void> _loadEmergencyContact() async {
    final contact = await DatabaseService.getEmergencyContact();
    if (!mounted) return;
    setState(() => _emergencyContact = contact);
  }

  /// [localeCode] is 'en', 'he', or 'ar'.
  Future<void> _saveLanguage(String localeCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', localeCode);
    if (!mounted) return;
    setState(() => _selectedLocaleCode = localeCode);
    widget.onLocaleChanged(Locale(localeCode));
  }

  Future<void> _saveTTS(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tts_enabled', enabled);
    if (!mounted) return;
    setState(() => _ttsEnabled = enabled);
  }

  Future<void> _saveFreeMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('free_mode_enabled', enabled);
    if (!mounted) return;
    setState(() => _freeModeEnabled = enabled);
  }

  Future<void> _saveAiDetection(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_detection_enabled', enabled);
    if (!mounted) return;
    setState(() => _aiDetectionEnabled = enabled);
  }

  void _showEmergencyContactDialog() {
    final l10n = AppLocalizations.of(context)!;
    final nameController  = TextEditingController(text: _emergencyContact?['name']         ?? '');
    final phoneController = TextEditingController(text: _emergencyContact?['phone_number'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        final dialogCs = Theme.of(context).colorScheme;
        return Dialog(
          backgroundColor: dialogCs.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.contact_phone, color: dialogCs.primary),
                    const SizedBox(width: 10),
                    Text(
                      l10n.settingsContactDialogTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.settingsContactName,
                    prefixIcon: Icon(Icons.person, color: dialogCs.outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.settingsContactPhone,
                    prefixIcon: Icon(Icons.phone, color: dialogCs.outline),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_emergencyContact != null)
                      TextButton(
                        onPressed: () async {
                          final nav       = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          await DatabaseService.deleteEmergencyContact();
                          await _loadEmergencyContact();
                          if (mounted) {
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.settingsContactDeleted)),
                            );
                          }
                        },
                        child: Text(l10n.settingsContactDelete,
                            style: TextStyle(color: dialogCs.error)),
                      ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.settingsCancel),
                    ),
                    const SizedBox(width: 8),
                    GradientButton(
                      gradientColors: [dialogCs.primary, dialogCs.primaryContainer],
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      onTap: () async {
                        final name  = nameController.text.trim();
                        final phone = phoneController.text.trim();
                        if (name.isEmpty || phone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.settingsContactValidation)),
                          );
                          return;
                        }
                        final nav       = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        await DatabaseService.saveEmergencyContact(name, phone);
                        await _loadEmergencyContact();
                        if (mounted) {
                          nav.pop();
                          messenger.showSnackBar(
                            SnackBar(content: Text(l10n.settingsContactSaved(name))),
                          );
                        }
                      },
                      child: Text(
                        l10n.settingsContactSave,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: dialogCs.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _callEmergencyContact() async {
    if (_emergencyContact == null) return;
    final l10n  = AppLocalizations.of(context)!;
    final phone = _emergencyContact!['phone_number'] as String;
    await PhoneService.call(phone, context, l10n.settingsCallFailed);
  }

  Future<void> _showLocationDialog() =>
      ShareLocationSheet.show(context);

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.settingsSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 28),

            // ── Preferences ──
            _buildSectionHeader(l10n.settingsSectionPreferences),
            const SizedBox(height: 12),

            _buildSettingCard(
              icon: Icons.language,
              iconColor: cs.tertiary,
              title: l10n.settingsLanguage,
              subtitle: _nativeLanguageName(_selectedLocaleCode),
              onTap: _showLanguageDialog,
            ),
            _buildSettingCard(
              icon: Icons.brightness_6_outlined,
              iconColor: cs.tertiary,
              title: l10n.settingsTheme,
              subtitle: _themeModeLabel(l10n, _themeMode),
              onTap: _showThemeDialog,
            ),
            _buildSwitchCard(
              icon: Icons.record_voice_over,
              iconColor: cs.tertiary,
              title: l10n.settingsVoiceGuidance,
              subtitle: l10n.settingsTtsSubtitle,
              value: _ttsEnabled,
              onChanged: _saveTTS,
            ),
            _buildSwitchCard(
              icon: Icons.mic_none,
              iconColor: cs.tertiary,
              title: l10n.settingsFreeMode,
              subtitle: l10n.settingsFreeModeSubtitle,
              value: _freeModeEnabled,
              onChanged: _saveFreeMode,
            ),
            _buildSwitchCard(
              icon: Icons.auto_awesome,
              iconColor: cs.tertiary,
              title: l10n.settingsAiDetection,
              subtitle: l10n.settingsAiDetectionSubtitle,
              value: _aiDetectionEnabled,
              onChanged: _saveAiDetection,
            ),

            const SizedBox(height: 32),

            // ── Emergency Contact ──
            _buildSectionHeader(l10n.settingsSectionEmergencyContact),
            const SizedBox(height: 12),

            _emergencyContact != null
                ? Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(Icons.contact_phone, color: cs.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _emergencyContact!['name'],
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _emergencyContact!['phone_number'],
                                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.phone, color: cs.tertiary),
                          onPressed: _callEmergencyContact,
                          tooltip: l10n.settingsCallContactTooltip,
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, color: cs.outline),
                          onPressed: _showEmergencyContactDialog,
                          tooltip: l10n.settingsEditContactTooltip,
                        ),
                      ],
                    ),
                  )
                : _buildSettingCard(
                    icon: Icons.person_add,
                    iconColor: cs.primary,
                    title: l10n.settingsAddContact,
                    subtitle: l10n.settingsAddContactSubtitle,
                    onTap: _showEmergencyContactDialog,
                  ),

            const SizedBox(height: 8),

            // ── Location Tools ──
            _buildSectionHeader(l10n.settingsSectionLocation),
            const SizedBox(height: 12),

            _buildSettingCard(
              icon: Icons.location_on,
              iconColor: cs.tertiary,
              title: l10n.settingsShareLocation,
              subtitle: l10n.settingsShareLocationSubtitle,
              onTap: _showLocationDialog,
            ),

            const SizedBox(height: 32),

            // ── Information ──
            _buildSectionHeader(l10n.settingsSectionInfo),
            const SizedBox(height: 12),

            _buildSettingCard(
              icon: Icons.verified_user,
              iconColor: cs.secondary,
              title: l10n.settingsMedicalSources,
              subtitle: l10n.settingsMedicalSourcesSubtitle,
              onTap: _showMedicalSourcesDialog,
            ),
            _buildSettingCard(
              icon: Icons.history,
              iconColor: cs.tertiary,
              title: l10n.settingsIncidentLog,
              subtitle: l10n.settingsIncidentLogSubtitle,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IncidentLogScreen(),
                  ),
                );
              },
            ),
            _buildSettingCard(
              icon: Icons.info_outline,
              iconColor: cs.outline,
              title: l10n.settingsAbout,
              subtitle: l10n.settingsAboutSubtitle,
              onTap: _showAboutDialog,
            ),

            const SizedBox(height: 32),

            // ── Disclaimer Notice ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsDisclaimerTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.settingsDisclaimerBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Reusable card widgets ────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: cs.outline,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            // Chevron flips in RTL
            Icon(isRtl ? Icons.chevron_left : Icons.chevron_right,
                color: cs.outline, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: cs.primary,
        activeTrackColor: cs.primaryContainer,
      ),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────

  void _showThemeDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        final dialogCs = Theme.of(context).colorScheme;
        return Dialog(
          backgroundColor: dialogCs.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    l10n.settingsThemeDialogTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                _buildThemeOption(ThemeMode.system, l10n.settingsThemeSystem, Icons.brightness_auto),
                _buildThemeOption(ThemeMode.light,  l10n.settingsThemeLight,  Icons.light_mode_outlined),
                _buildThemeOption(ThemeMode.dark,   l10n.settingsThemeDark,   Icons.dark_mode_outlined),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.settingsCancel),
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

  Widget _buildThemeOption(ThemeMode mode, String label, IconData icon) {
    final cs         = Theme.of(context).colorScheme;
    final isSelected = _themeMode == mode;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: isSelected ? cs.primary : cs.outline),
      title: Text(label, style: Theme.of(context).textTheme.titleMedium),
      trailing: isSelected ? Icon(Icons.check_circle, color: cs.primary) : null,
      onTap: () {
        _saveThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        final dialogCs = Theme.of(context).colorScheme;
        return Dialog(
          backgroundColor: dialogCs.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    l10n.settingsSelectLanguage,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                // Language names are always shown in their own script — not translated
                _buildLanguageOption('en', 'English'),
                _buildLanguageOption('he', 'עברית'),
                _buildLanguageOption('ar', 'العربية'),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.settingsCancel),
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

  Widget _buildLanguageOption(String localeCode, String nativeName) {
    final cs         = Theme.of(context).colorScheme;
    final isSelected = _selectedLocaleCode == localeCode;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(nativeName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w400)),
      trailing: isSelected ? Icon(Icons.check_circle, color: cs.primary) : null,
      onTap: () {
        _saveLanguage(localeCode);
        Navigator.pop(context);
      },
    );
  }

  void _showMedicalSourcesDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        final dialogCs = Theme.of(context).colorScheme;
        final theme    = Theme.of(context);
        final dl10n    = AppLocalizations.of(context)!;
        return Dialog(
          backgroundColor: dialogCs.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user, color: dialogCs.primary),
                    const SizedBox(width: 10),
                    Text(
                      dl10n.settingsSourcesDialogTitle,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  dl10n.settingsSourcesIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SourceItem(title: dl10n.settingsSourcesRedCrossTitle, subtitle: dl10n.settingsSourcesRedCrossSubtitle),
                SourceItem(title: dl10n.settingsSourcesWHOTitle,      subtitle: dl10n.settingsSourcesWHOSubtitle),
                SourceItem(title: dl10n.settingsSourcesAHATitle,      subtitle: dl10n.settingsSourcesAHASubtitle),
                SourceItem(title: dl10n.settingsSourcesMDATitle,      subtitle: dl10n.settingsSourcesMDASubtitle),
                const SizedBox(height: 16),
                Text(
                  dl10n.settingsSourcesLastVerified,
                  style: theme.textTheme.labelSmall?.copyWith(color: dialogCs.outline),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.settingsClose),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAboutDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        final dialogCs = Theme.of(context).colorScheme;
        final theme    = Theme.of(context);
        final dl10n    = AppLocalizations.of(context)!;
        return Dialog(
          backgroundColor: dialogCs.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medical_services, color: dialogCs.primary),
                    const SizedBox(width: 10),
                    Text(
                      dl10n.settingsAboutDialogTitle,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  dl10n.appName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: dialogCs.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(dl10n.settingsAboutVersion,
                    style: theme.textTheme.bodyMedium?.copyWith(color: dialogCs.outline)),
                const SizedBox(height: 16),
                Text(dl10n.settingsAboutDescription, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                Text(dl10n.settingsAboutDevelopedBy,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Text('Mohammad Quttaineh', style: theme.textTheme.bodyLarge),
                Text('Amru Alyan',         style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                Text(
                  dl10n.settingsAboutCopyright,
                  style: theme.textTheme.labelSmall?.copyWith(color: dialogCs.outline),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.settingsClose),
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

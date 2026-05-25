import 'package:flutter/material.dart';
import 'package:guardian_angel/l10n/app_localizations.dart';
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
  String _searchQuery = '';

  /// Built inside build() so titles are always in the active locale.
  List<Map<String, dynamic>> _buildEmergencyList(AppLocalizations l10n) => [
    {'id': 'choking',         'title': l10n.emergencyChoking,        'icon': Icons.air,                        'color': AppColors.chokingBlue},
    {'id': 'choking_infant',  'title': l10n.emergencyChokingInfant,  'icon': Icons.baby_changing_station,      'color': AppColors.chokingBlue},
    {'id': 'cpr',             'title': l10n.emergencyCPR,            'icon': Icons.favorite,                   'color': AppColors.cprRed},
    {'id': 'cpr_infant',      'title': l10n.emergencyCPRInfant,      'icon': Icons.monitor_heart,              'color': AppColors.cprRed},
    {'id': 'burns',           'title': l10n.emergencyBurns,          'icon': Icons.local_fire_department,      'color': AppColors.burnOrange},
    {'id': 'bleeding',        'title': l10n.emergencyBleeding,       'icon': Icons.water_drop,                 'color': AppColors.bleedingCrimson},
    {'id': 'fractures',       'title': l10n.emergencyFractures,      'icon': Icons.healing,                    'color': AppColors.fracturePurple},
    {'id': 'seizures',        'title': l10n.emergencySeizures,       'icon': Icons.warning_amber_rounded,      'color': AppColors.seizureAmber},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          emergencyId:    id,
          emergencyTitle: title,
          emergencyColor: color,
          incidentLogId:  incidentLogId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    final allEmergencies      = _buildEmergencyList(l10n);
    final query = _searchQuery.toLowerCase();
    final filteredEmergencies = _searchQuery.isEmpty
        ? allEmergencies
        : allEmergencies
            .where((e) => (e['title'] as String).toLowerCase().contains(query))
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.homeSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  // Settings icon
                  IconButton(
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
                ],
              ),
              const SizedBox(height: 24),

              // ── Section title ──
              Text(
                l10n.homeSelectEmergency,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // ── Search Bar ──
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: l10n.homeSearchHint,
                  prefixIcon: Icon(Icons.search, color: cs.outline),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: cs.outline),
                          onPressed: () => setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          }),
                        )
                      : null,
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
                    : GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        padding: EdgeInsets.only(
                          bottom: 64 + 16 + MediaQuery.of(context).padding.bottom,
                        ),
                        children: filteredEmergencies
                            .map((e) => _buildEmergencyCard(
                                  context,
                                  id:    e['id']    as String,
                                  title: e['title'] as String,
                                  icon:  e['icon']  as IconData,
                                  color: e['color'] as Color,
                                ))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),

      // ── SOS FAB ──
      floatingActionButton: Builder(
        builder: (context) {
          final fabCs  = Theme.of(context).colorScheme;
          final fabL10n = AppLocalizations.of(context)!;
          return Semantics(
            button: true,
            label: fabL10n.homeCallBtn,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-0.97, -0.26),
                  end: const Alignment(0.97, 0.26),
                  colors: [fabCs.primary, fabCs.primaryContainer],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: fabCs.onSurface.withValues(alpha: 0.08),
                    offset: const Offset(0, 16),
                    blurRadius: 40,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: () => PhoneService.call(
                    '101', context, fabL10n.homeCallFailed,
                    duration: const Duration(seconds: 3),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone, color: fabCs.onPrimary, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          fabL10n.homeCallBtn,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: fabCs.onPrimary,
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
        },
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
    );
  }
}

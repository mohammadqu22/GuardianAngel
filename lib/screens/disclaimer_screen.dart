import 'package:flutter/material.dart';
import 'package:guardian_angel/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../core/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/source_item.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({
    super.key,
    required this.onThemeModeChanged,
    required this.onLocaleChanged,
  });

  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Locale> onLocaleChanged;

  Future<void> _acceptDisclaimer(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disclaimer_accepted', true);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            onThemeModeChanged: onThemeModeChanged,
            onLocaleChanged: onLocaleChanged,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),

                      // ── App Icon and Title ──
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.medical_services,
                                size: 56,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              l10n.appName,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.disclaimerSubtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── Important Notice ──
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.disclaimerNoticeTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.disclaimerNoticeBody1,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: cs.onSurface,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.disclaimerNoticeBody2,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: cs.onSurface,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Emergency Instructions ──
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_in_talk,
                                  color: cs.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.disclaimerEmergencyTitle,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildBulletPoint(context, l10n.disclaimerBullet1),
                            _buildBulletPoint(context, l10n.disclaimerBullet2),
                            _buildBulletPoint(context, l10n.disclaimerBullet3),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Medical Sources ──
                      Text(
                        l10n.disclaimerSourcesTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SourceItem(
                        title: l10n.disclaimerSource1,
                        icon: Icons.verified,
                        iconSize: 18,
                        bottomPadding: 10,
                      ),
                      SourceItem(
                        title: l10n.disclaimerSource2,
                        icon: Icons.verified,
                        iconSize: 18,
                        bottomPadding: 10,
                      ),
                      SourceItem(
                        title: l10n.disclaimerSource3,
                        icon: Icons.verified,
                        iconSize: 18,
                        bottomPadding: 10,
                      ),
                      SourceItem(
                        title: l10n.disclaimerSource4,
                        icon: Icons.verified,
                        iconSize: 18,
                        bottomPadding: 10,
                      ),

                      const SizedBox(height: 24),

                      // ── Legal Notice ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          l10n.disclaimerAcknowledge,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          l10n.disclaimerVersion,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Accept Button ──
              GradientButton(
                width: double.infinity,
                height: 56,
                boxShadow: [
                  BoxShadow(
                    color: cs.onSurface.withValues(alpha: 0.08),
                    offset: const Offset(0, 16),
                    blurRadius: 40,
                  ),
                ],
                onTap: () => _acceptDisclaimer(context),
                child: Center(
                  child: Text(
                    l10n.disclaimerContinueBtn,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: cs.primary, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

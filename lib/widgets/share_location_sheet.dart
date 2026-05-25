import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/location_service.dart';

class ShareLocationSheet {
  /// Fetches the current location, then shows a bottom sheet with three
  /// share options: WhatsApp, SMS, and Copy to clipboard.
  static Future<void> show(
    BuildContext context, {
    Color? accentColor,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    // Show a loading dialog while GPS resolves.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Dialog(
          backgroundColor: cs.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: cs.primary),
                const SizedBox(width: 16),
                Text(l10n.settingsLocationFetching),
              ],
            ),
          ),
        );
      },
    );

    final position = await LocationService.getCurrentLocation();
    if (context.mounted) Navigator.pop(context);

    if (position == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsLocationFailed)),
        );
      }
      return;
    }

    final mapsLink = LocationService.getMapsLink(position);
    final message = l10n.locationShareMessage(mapsLink);

    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => _ShareSheet(
        mapsLink: mapsLink,
        message: message,
        accentColor: accentColor,
      ),
    );
  }
}

class _ShareSheet extends StatelessWidget {
  final String mapsLink;
  final String message;
  final Color? accentColor;

  const _ShareSheet({
    required this.mapsLink,
    required this.message,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = accentColor ?? cs.primary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // CrossAxisAlignment.start is direction-aware:
          // aligns left in LTR, right in RTL.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar — always centered
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title row — Row respects ambient Directionality
            Row(
              children: [
                Icon(Icons.location_on, color: color, size: 22),
                const SizedBox(width: 10),
                Text(
                  l10n.locationShareTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // WhatsApp
            _ShareButton(
              icon: FaIcon(
                FontAwesomeIcons.whatsapp,
                color: const Color(0xFF25D366),
                size: 20,
              ),
              label: l10n.locationShareWhatsApp,
              onTap: () => _shareWhatsApp(context, message, l10n),
            ),
            const SizedBox(height: 12),

            // SMS
            _ShareButton(
              icon: Icon(Icons.sms, color: color, size: 20),
              label: l10n.locationShareSms,
              onTap: () => _shareSms(context, message, l10n),
            ),
            const SizedBox(height: 12),

            // Copy
            _ShareButton(
              icon: Icon(Icons.copy, color: cs.secondary, size: 20),
              label: l10n.settingsLocationCopy,
              onTap: () => _copyToClipboard(context, mapsLink, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareWhatsApp(
    BuildContext context,
    String message,
    AppLocalizations l10n,
  ) async {
    Navigator.pop(context);
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/?text=$encoded');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.locationShareNotAvailable)),
        );
      }
    }
  }

  Future<void> _shareSms(
    BuildContext context,
    String message,
    AppLocalizations l10n,
  ) async {
    Navigator.pop(context);
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:?body=$encoded');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.locationShareNotAvailable)),
        );
      }
    }
  }

  void _copyToClipboard(
    BuildContext context,
    String link,
    AppLocalizations l10n,
  ) {
    Clipboard.setData(ClipboardData(text: link));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsLocationCopied)),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: icon,
        label: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          // AlignmentDirectional.centerStart = left in LTR, right in RTL
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          side: BorderSide(color: cs.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}

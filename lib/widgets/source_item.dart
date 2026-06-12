import 'package:flutter/material.dart';

/// A row with a coloured icon on the left and one or two lines of text on the right.
///
/// Used to display medical source entries in both DisclaimerScreen (single line)
/// and SettingsScreen medical sources dialog (title + subtitle).
class SourceItem extends StatelessWidget {
  const SourceItem({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.check_circle,
    this.iconSize = 20.0,
    this.bottomPadding = 12.0,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final double iconSize;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.tertiary, size: iconSize),
          const SizedBox(width: 10),
          Expanded(
            child: subtitle != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                : Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

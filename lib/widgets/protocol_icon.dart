import 'package:flutter/material.dart';

/// Renders the custom icon for an emergency protocol.
///
/// The icon art is pre-colored PNGs (one per protocol id), so [color] is not
/// applied as a tint — it styles the fallback [Icon] shown when no asset
/// exists for the id or the asset fails to load.
class ProtocolIcon extends StatelessWidget {
  const ProtocolIcon({
    super.key,
    required this.emergencyId,
    required this.color,
    this.size = 40,
    this.fallbackIcon = Icons.medical_services_outlined,
  });

  final String emergencyId;
  final Color color;
  final double size;
  final IconData fallbackIcon;

  /// Icon assets follow a single naming convention, so new protocols get an
  /// icon by dropping a matching PNG into assets/icons/protocols/.
  static String assetFor(String emergencyId) =>
      'assets/icons/protocols/$emergencyId.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetFor(emergencyId),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) =>
          Icon(fallbackIcon, color: color, size: size),
    );
  }
}

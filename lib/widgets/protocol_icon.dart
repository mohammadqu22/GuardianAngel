import 'package:flutter/material.dart';

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

  static String? assetFor(String emergencyId) {
    return switch (emergencyId) {
      'choking' => 'assets/icons/protocols/choking.png',
      'choking_infant' => 'assets/icons/protocols/choking_infant.png',
      'cpr' => 'assets/icons/protocols/cpr.png',
      'cpr_infant' => 'assets/icons/protocols/cpr_infant.png',
      'burns' => 'assets/icons/protocols/burns.png',
      'bleeding' => 'assets/icons/protocols/bleeding.png',
      'fractures' => 'assets/icons/protocols/fractures.png',
      'seizures' => 'assets/icons/protocols/seizures.png',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final asset = assetFor(emergencyId);
    if (asset == null) {
      return Icon(fallbackIcon, color: color, size: size);
    }

    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}

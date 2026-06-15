import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// A tappable button with a near-horizontal diagonal linear gradient background
/// (begin: Alignment(-0.97, -0.26) → end: Alignment(0.97, 0.26), ≈15° tilt).
///
/// Replaces the repeated `Container → LinearGradient → Material → InkWell`
/// pattern used for primary action buttons throughout the app.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onTap,
    required this.child,
    this.gradientColors,
    this.borderRadius = AppRadius.md,
    this.height,
    this.width,
    this.padding,
    this.boxShadow,
  });

  final VoidCallback onTap;
  final Widget child;

  /// Gradient stop colors (left → right).
  /// Defaults to `[colorScheme.primary, colorScheme.primaryContainer]`.
  final List<Color>? gradientColors;

  final double borderRadius;
  final double? height;
  final double? width;

  /// Inner padding applied around [child]. Pass `null` for no padding wrapper
  /// (useful when you need the child to fill the button, e.g. a centred Row).
  final EdgeInsetsGeometry? padding;

  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = gradientColors ?? [cs.primary, cs.primaryContainer];
    final radius = BorderRadius.circular(borderRadius);

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.97, -0.26),
          end: const Alignment(0.97, 0.26),
          colors: colors,
        ),
        borderRadius: radius,
        boxShadow: boxShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: padding != null
              ? Padding(padding: padding!, child: child)
              : child,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design System: "The Clinical Sentinel"
/// Extracted from Google Stitch project 18416799649176081778
///
/// Design principles:
/// - Tonal layering instead of drop shadows
/// - "No-Line" rule: no 1px borders for sectioning
/// - "Ghost Border": outline_variant at 15% opacity
/// - Gradient CTAs: primary → primary_container at 15°
/// - Minimum 48dp touch targets, 64dp for SOS

// ───────────────────────────────────────────────
// Color Tokens
// ───────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = Color(0xFFB7131A);
  static const Color primaryContainer = Color(0xFFDB322F);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFFFFBFF);
  static const Color primaryFixed = Color(0xFFFFDAD6);
  static const Color primaryFixedDim = Color(0xFFFFB4AC);

  // Secondary palette
  static const Color secondary = Color(0xFFA13D36);
  static const Color secondaryContainer = Color(0xFFFF857A);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF751D19);

  // Tertiary palette
  static const Color tertiary = Color(0xFF006578);
  static const Color tertiaryContainer = Color(0xFF008097);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFF9FDFF);

  // Surface tiers (surgical paper layers)
  static const Color surface = Color(0xFFF9F9F9);
  static const Color surfaceBright = Color(0xFFF9F9F9);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E2);
  static const Color surfaceContainerLow = Color(0xFFF3F3F4);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFDADADA);
  static const Color surfaceTint = Color(0xFFBB171C);
  static const Color surfaceVariant = Color(0xFFE2E2E2);

  // On-surface
  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color onSurfaceVariant = Color(0xFF5B403D);
  static const Color inverseSurface = Color(0xFF2F3131);
  static const Color inverseOnSurface = Color(0xFFF0F1F1);
  static const Color inversePrimary = Color(0xFFFFB4AC);

  // Outline
  static const Color outline = Color(0xFF906F6C);
  static const Color outlineVariant = Color(0xFFE4BEB9);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Background
  static const Color background = Color(0xFFF9F9F9);
  static const Color onBackground = Color(0xFF1A1C1C);

  // ── Category accents (for emergency type chips/cards) ──
  static const Color burnOrange = Color(0xFFFF5722);
  static const Color chokingBlue = Color(0xFF2196F3);
  static const Color cprRed = Color(0xFFE53935);
  static const Color bleedingCrimson = Color(0xFFD32F2F);
  static const Color fracturePurple = Color(0xFF9C27B0);
  static const Color seizureAmber = Color(0xFFFFA726);

  // ── Learning Mode (quiz feedback + medals) ──
  static const Color quizCorrectGreen = Color(0xFF2E7D32);
  static const Color medalGold = Color(0xFFFFB300);
  static const Color medalSilver = Color(0xFF90A4AE);
  static const Color medalBronze = Color(0xFFB07C4F);
}

// ───────────────────────────────────────────────
// Gradients
// ───────────────────────────────────────────────

class AppGradients {
  AppGradients._();

  /// Urgent CTA gradient: primary → primaryContainer at ~15°
  static const LinearGradient urgentCta = LinearGradient(
    begin: Alignment(-0.97, -0.26), // approx 15°
    end: Alignment(0.97, 0.26),
    colors: [AppColors.primary, AppColors.primaryContainer],
  );

  /// Dark mode urgent CTA gradient: primary → primaryContainer at ~15°
  static const LinearGradient urgentCtaDark = LinearGradient(
    begin: Alignment(-0.97, -0.26), // approx 15°
    end: Alignment(0.97, 0.26),
    colors: [AppColorsDark.primary, AppColorsDark.primaryContainer],
  );
}

// ───────────────────────────────────────────────
// Elevation / Depth
// ───────────────────────────────────────────────

class AppElevation {
  AppElevation._();

  /// Ambient shadow for floating elements (light mode)
  static BoxShadow ambientShadow = BoxShadow(
    color: AppColors.onSurface.withValues(alpha: 0.08),
    offset: const Offset(0, 16),
    blurRadius: 40,
  );

  /// Ambient shadow for floating elements (dark mode)
  static BoxShadow ambientShadowDark = BoxShadow(
    color: AppColorsDark.onSurface.withValues(alpha: 0.08),
    offset: const Offset(0, 16),
    blurRadius: 40,
  );

  /// Ghost border — outlineVariant at 15% opacity (light mode)
  static Color ghostBorder = AppColors.outlineVariant.withValues(alpha: 0.15);

  /// Ghost border — outlineVariant at 15% opacity (dark mode)
  static Color ghostBorderDark = AppColorsDark.outlineVariant.withValues(alpha: 0.15);
}

// ───────────────────────────────────────────────
// Spacing
// ───────────────────────────────────────────────

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

// ───────────────────────────────────────────────
// Radii — ROUND_FOUR from Stitch
// ───────────────────────────────────────────────

class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
}

// ───────────────────────────────────────────────
// Dark Mode Color Tokens
// ───────────────────────────────────────────────

class AppColorsDark {
  AppColorsDark._();

  // Primary palette
  static const Color primary = Color(0xFFFFB4AC);
  static const Color primaryContainer = Color(0xFFFF544C);
  static const Color onPrimary = Color(0xFF690006);
  static const Color onPrimaryContainer = Color(0xFFFFEDEB);

  // Secondary palette
  static const Color secondary = Color(0xFF9ECAFF);
  static const Color secondaryContainer = Color(0xFF1E95F2);
  static const Color onSecondary = Color(0xFF003355);
  static const Color onSecondaryContainer = Color(0xFFFFFFFF);

  // Tertiary palette
  static const Color tertiary = Color(0xFFF9ABFF);
  static const Color tertiaryContainer = Color(0xFFD560E6);
  static const Color onTertiary = Color(0xFF3D0051);
  static const Color onTertiaryContainer = Color(0xFFFFFFFF);

  // Surface tiers (surgical dark paper layers)
  static const Color surface = Color(0xFF131313);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest = Color(0xFF353534);
  static const Color surfaceContainerLow = Color(0xFF1C1B1B);
  static const Color surfaceContainerLowest = Color(0xFF0E0E0E);
  static const Color surfaceVariant = Color(0xFF353534);
  static const Color surfaceTint = Color(0xFFFFB4AC);

  // On-surface
  static const Color onSurface = Color(0xFFE5E2E1);
  static const Color onSurfaceVariant = Color(0xFFE4BEB9);
  static const Color inverseSurface = Color(0xFFF9F9F9);
  static const Color inverseOnSurface = Color(0xFF1A1C1C);
  static const Color inversePrimary = Color(0xFFB7131A);

  // Outline
  static const Color outline = Color(0xFFAB8985);
  static const Color outlineVariant = Color(0xFF5B403D);

  // Error
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onError = Color(0xFF690006);
  static const Color onErrorContainer = Color(0xFFFFDAD6);
}

// ───────────────────────────────────────────────
// Theme helpers
// ───────────────────────────────────────────────

ThemeMode themeModeFromString(String value) {
  switch (value) {
    case 'light': return ThemeMode.light;
    case 'dark':  return ThemeMode.dark;
    default:      return ThemeMode.system;
  }
}

// ───────────────────────────────────────────────
// ThemeData builder
// ───────────────────────────────────────────────

ThemeData buildAppTheme() {
  final textTheme = GoogleFonts.publicSansTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: GoogleFonts.publicSans().fontFamily,

    // ── Color Scheme ──
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      inversePrimary: AppColors.inversePrimary,
      surfaceTint: AppColors.surfaceTint,
    ),

    scaffoldBackgroundColor: AppColors.surface,

    // ── AppBar ──
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.onSurface,
        fontSize: 20,
      ),
    ),

    // ── Text Theme ──
    textTheme: textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(
        fontSize: 56,
        fontWeight: FontWeight.bold,
        color: AppColors.onSurface,
      ),
      headlineLarge: textTheme.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.onSurface,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.onSurface,
      ),
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.onSurface,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurface,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(
        fontSize: 16,
        color: AppColors.onSurface,
        height: 1.6,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: AppColors.onSurfaceVariant,
      ),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
      labelSmall: textTheme.labelSmall?.copyWith(
        fontSize: 11,
        color: AppColors.onSurfaceVariant,
      ),
    ),

    // ── Elevated Button ──
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: 0,
        textStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),

    // ── Outlined Button ──
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ── Card ──
    cardTheme: CardThemeData(
      color: AppColors.surfaceContainerLow,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),

    // ── FAB ──
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      shape: StadiumBorder(),
    ),

    // ── Progress Indicator ──
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.surfaceVariant,
      linearMinHeight: 8,
    ),

    // ── Switch ──
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return AppColors.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primaryFixed;
        return AppColors.surfaceContainerHighest;
      }),
    ),

    // ── Dialog ──
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    ),

    // ── Divider ──
    dividerTheme: const DividerThemeData(
      color: Colors.transparent, // No-Line rule
      thickness: 0,
    ),

    // ── Input Decoration ──
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      hintStyle: TextStyle(color: AppColors.outline),
    ),
  );
}

ThemeData buildDarkTheme() {
  final textTheme = GoogleFonts.publicSansTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.publicSans().fontFamily,

    // ── Color Scheme ──
    colorScheme: const ColorScheme.dark(
      primary: AppColorsDark.primary,
      onPrimary: AppColorsDark.onPrimary,
      primaryContainer: AppColorsDark.primaryContainer,
      onPrimaryContainer: AppColorsDark.onPrimaryContainer,
      secondary: AppColorsDark.secondary,
      onSecondary: AppColorsDark.onSecondary,
      secondaryContainer: AppColorsDark.secondaryContainer,
      onSecondaryContainer: AppColorsDark.onSecondaryContainer,
      tertiary: AppColorsDark.tertiary,
      onTertiary: AppColorsDark.onTertiary,
      tertiaryContainer: AppColorsDark.tertiaryContainer,
      onTertiaryContainer: AppColorsDark.onTertiaryContainer,
      error: AppColorsDark.error,
      onError: AppColorsDark.onError,
      errorContainer: AppColorsDark.errorContainer,
      onErrorContainer: AppColorsDark.onErrorContainer,
      surface: AppColorsDark.surface,
      onSurface: AppColorsDark.onSurface,
      onSurfaceVariant: AppColorsDark.onSurfaceVariant,
      surfaceContainerLowest: AppColorsDark.surfaceContainerLowest,
      surfaceContainerLow: AppColorsDark.surfaceContainerLow,
      surfaceContainer: AppColorsDark.surfaceContainer,
      surfaceContainerHigh: AppColorsDark.surfaceContainerHigh,
      surfaceContainerHighest: AppColorsDark.surfaceContainerHighest,
      outline: AppColorsDark.outline,
      outlineVariant: AppColorsDark.outlineVariant,
      inverseSurface: AppColorsDark.inverseSurface,
      onInverseSurface: AppColorsDark.inverseOnSurface,
      inversePrimary: AppColorsDark.inversePrimary,
      surfaceTint: AppColorsDark.surfaceTint,
    ),

    scaffoldBackgroundColor: AppColorsDark.surface,

    // ── AppBar ──
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorsDark.surface,
      foregroundColor: AppColorsDark.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColorsDark.onSurface,
        fontSize: 20,
      ),
    ),

    // ── Text Theme ──
    textTheme: textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(
        fontSize: 56,
        fontWeight: FontWeight.bold,
        color: AppColorsDark.onSurface,
      ),
      headlineLarge: textTheme.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColorsDark.onSurface,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColorsDark.onSurface,
      ),
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColorsDark.onSurface,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColorsDark.onSurface,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColorsDark.onSurface,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(
        fontSize: 16,
        color: AppColorsDark.onSurface,
        height: 1.6,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: AppColorsDark.onSurfaceVariant,
      ),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColorsDark.onSurface,
      ),
      labelSmall: textTheme.labelSmall?.copyWith(
        fontSize: 11,
        color: AppColorsDark.onSurfaceVariant,
      ),
    ),

    // ── Elevated Button ──
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsDark.primary,
        foregroundColor: AppColorsDark.onPrimary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: 0,
        textStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),

    // ── Outlined Button ──
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColorsDark.primary,
        side: const BorderSide(color: AppColorsDark.primary, width: 1.5),
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ── Card ──
    cardTheme: CardThemeData(
      color: AppColorsDark.surfaceContainerLow,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),

    // ── FAB ──
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColorsDark.primary,
      foregroundColor: AppColorsDark.onPrimary,
      elevation: 0,
      shape: StadiumBorder(),
    ),

    // ── Progress Indicator ──
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColorsDark.primary,
      linearTrackColor: AppColorsDark.surfaceVariant,
      linearMinHeight: 8,
    ),

    // ── Switch ──
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColorsDark.primary;
        return AppColorsDark.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColorsDark.primaryContainer;
        return AppColorsDark.surfaceContainerHighest;
      }),
    ),

    // ── Dialog ──
    dialogTheme: DialogThemeData(
      backgroundColor: AppColorsDark.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    ),

    // ── Divider ──
    dividerTheme: const DividerThemeData(
      color: Colors.transparent, // No-Line rule
      thickness: 0,
    ),

    // ── Input Decoration ──
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColorsDark.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColorsDark.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      hintStyle: TextStyle(color: AppColorsDark.outline),
    ),
  );
}

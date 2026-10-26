import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radii.dart';

/// Atelier Acoustique Theme Configuration
/// Translates DESIGN.md tokens into Flutter's ThemeData and custom decoration helpers.
abstract final class AppTheme {
  /// Dark ThemeData for the acoustic instrument aesthetic.
  static ThemeData get darkTheme {
    final textTheme = AppTypography.createTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.neutralCanvas,
      canvasColor: AppColors.neutralCanvas,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondaryAccent,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        error: AppColors.error,
        onError: AppColors.onError,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      textTheme: textTheme,
      fontFamily: AppTypography.primaryFont,
      dividerColor: AppColors.ghostBorder,
      dividerTheme: const DividerThemeData(
        color: AppColors.ghostBorder,
        thickness: 1,
        space: 1,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.radiusDefault,
          side: BorderSide(color: AppColors.ghostBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.neutralCanvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMd(color: AppColors.primaryText),
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.secondaryAccent,
        inactiveTrackColor: AppColors.ghostBorderSubtle,
        thumbColor: AppColors.primaryText,
        overlayColor: AppColors.ghostBorderActive,
        trackHeight: 2.0,
      ),
    );
  }

  /// Frosted glassmorphic acrylic decoration helper
  static BoxDecoration frostedCardDecoration({
    bool isActive = false,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: AppColors.frostedGlass,
      borderRadius: borderRadius ?? AppRadii.radiusDefault,
      border: Border.all(
        color: isActive ? AppColors.ghostBorderActive : AppColors.ghostBorder,
        width: 1,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000), // diffused warm obsidian shadow
          blurRadius: 32,
          offset: Offset(0, 16),
        ),
      ],
    );
  }

  /// Recessed bay container decoration
  static BoxDecoration recessedBayDecoration({
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: AppColors.subSurface,
      borderRadius: borderRadius ?? AppRadii.radiusDefault,
      border: Border.all(color: AppColors.ghostBorder, width: 1),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Atelier Acoustique Typography System
/// Derived from DESIGN.md specification.
/// Features Hanken Grotesk for architectural editorial headings/body,
/// and JetBrains Mono for surgical audio telemetry and readouts.
abstract final class AppTypography {
  // Font Family Names
  static const String primaryFont = 'Hanken Grotesk';
  static const String monoFont = 'JetBrains Mono';

  // Desktop / Tablet Headline XL (56px, w300)
  static TextStyle headlineXl({Color color = AppColors.primaryText}) =>
      GoogleFonts.hankenGrotesk(
        fontSize: 56,
        fontWeight: FontWeight.w300,
        height: 64 / 56,
        letterSpacing: -0.03 * 56,
        color: color,
      );

  // Mobile Headline XL (36px, w300)
  static TextStyle headlineXlMobile({Color color = AppColors.primaryText}) =>
      GoogleFonts.hankenGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w300,
        height: 44 / 36,
        letterSpacing: -0.02 * 36,
        color: color,
      );

  // Desktop / Tablet Headline LG (40px, w400)
  static TextStyle headlineLg({Color color = AppColors.primaryText}) =>
      GoogleFonts.hankenGrotesk(
        fontSize: 40,
        fontWeight: FontWeight.w400,
        height: 48 / 40,
        letterSpacing: -0.02 * 40,
        color: color,
      );

  // Mobile Headline LG (28px, w400)
  static TextStyle headlineLgMobile({Color color = AppColors.primaryText}) =>
      GoogleFonts.hankenGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        height: 36 / 28,
        letterSpacing: -0.01 * 28,
        color: color,
      );

  // Headline MD (24px, w400)
  static TextStyle headlineMd({Color color = AppColors.primaryText}) =>
      GoogleFonts.hankenGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        height: 32 / 24,
        letterSpacing: -0.01 * 24,
        color: color,
      );

  // Body LG (18px, w300)
  static TextStyle bodyLg({Color color = AppColors.primaryText}) =>
      GoogleFonts.hankenGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w300,
        height: 28 / 18,
        letterSpacing: -0.005 * 18,
        color: color,
      );

  // Body MD (15px, w400)
  static TextStyle bodyMd({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.hankenGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 24 / 15,
        letterSpacing: 0,
        color: color,
      );

  // Body SM (13px, w400)
  static TextStyle bodySm({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.hankenGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 20 / 13,
        letterSpacing: 0.01 * 13,
        color: color,
      );

  // Label MD - Technical Readouts (12px, w500, JetBrains Mono)
  static TextStyle labelMd({Color color = AppColors.primaryText}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.08 * 12,
        color: color,
      );

  // Label SM - Technical Decibel / Calibration Readouts (10px, w500, JetBrains Mono)
  static TextStyle labelSm({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 14 / 10,
        letterSpacing: 0.12 * 10,
        color: color,
      );

  // Title LG / Headline MD (20px, w600)
  static TextStyle titleLg({Color color = AppColors.primaryText}) =>
      headlineMd(color: color);

  // Title MD (16px, w600)
  static TextStyle titleMd({Color color = AppColors.primaryText}) =>
      bodyLg(color: color).copyWith(fontWeight: FontWeight.w600, fontSize: 16);

  // Title SM (14px, w600)
  static TextStyle titleSm({Color color = AppColors.primaryText}) =>
      bodyMd(color: color).copyWith(fontWeight: FontWeight.w600, fontSize: 14);

  // Label LG (14px, w500)
  static TextStyle labelLg({Color color = AppColors.primaryText}) =>
      bodyMd(color: color).copyWith(fontWeight: FontWeight.w500, fontSize: 14);

  // Responsive Headline XL helper
  static TextStyle responsiveHeadlineXl(
    BuildContext context, {
    Color color = AppColors.primaryText,
  }) {
    final width = MediaQuery.of(context).size.width;
    return width < 768 ? headlineXlMobile(color: color) : headlineXl(color: color);
  }

  // Responsive Headline LG helper
  static TextStyle responsiveHeadlineLg(
    BuildContext context, {
    Color color = AppColors.primaryText,
  }) {
    final width = MediaQuery.of(context).size.width;
    return width < 768 ? headlineLgMobile(color: color) : headlineLg(color: color);
  }

  // Material TextTheme mapping
  static TextTheme createTextTheme() {
    return TextTheme(
      displayLarge: headlineXl(),
      displayMedium: headlineLg(),
      displaySmall: headlineMd(),
      headlineMedium: headlineMd(),
      titleLarge: headlineMd(),
      titleMedium: bodyLg(),
      titleSmall: bodyMd(),
      bodyLarge: bodyLg(),
      bodyMedium: bodyMd(),
      bodySmall: bodySm(),
      labelLarge: labelMd(),
      labelMedium: labelMd(),
      labelSmall: labelSm(),
    );
  }
}

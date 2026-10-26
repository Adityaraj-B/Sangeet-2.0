import 'package:flutter/material.dart';

/// Atelier Acoustique Color Palette
/// Derived from DESIGN.md specification.
/// Features deep warm obsidian, cashmere cream, and muted champagne gold.
abstract final class AppColors {
  // Brand Foundation - Obsidian & Cashmere
  static const Color neutralCanvas = Color(0xFF0A0A0B); // Deep warm obsidian black
  static const Color subSurface = Color(0xFF121112); // Recessed functional bays
  static const Color primaryText = Color(0xFFF5F4EF); // Cashmere cream / warm ivory
  static const Color secondaryAccent = Color(0xFFC5A880); // Muted champagne gold

  // Surface Spectrum
  static const Color surface = Color(0xFF131314);
  static const Color surfaceDim = Color(0xFF131314);
  static const Color surfaceBright = Color(0xFF3A393A);
  static const Color surfaceContainerLowest = Color(0xFF0E0E0F);
  static const Color surfaceContainerLow = Color(0xFF1C1B1C);
  static const Color surfaceContainer = Color(0xFF201F20);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2B);
  static const Color surfaceContainerHighest = Color(0xFF353436);
  static const Color surfaceVariant = Color(0xFF353436);

  // Content On Surfaces
  static const Color onSurface = Color(0xFFE5E2E3);
  static const Color onSurfaceVariant = Color(0xFFC6C7C0);
  static const Color inverseSurface = Color(0xFFE5E2E3);
  static const Color inverseOnSurface = Color(0xFF313031);

  // Structural Outlines & Dividers
  static const Color outline = Color(0xFF90918B);
  static const Color outlineVariant = Color(0xFF454742);
  static const Color surfaceTint = Color(0xFFC7C7C2);

  // Frosted & Ghost Hairline Borders
  static const Color ghostBorder = Color(0x14F5F4EF); // rgba(245, 244, 239, 0.08)
  static const Color ghostBorderActive = Color(0x59C5A880); // rgba(197, 168, 128, 0.35)
  static const Color ghostBorderSubtle = Color(0x1EF5F4EF); // rgba(245, 244, 239, 0.12)
  static const Color ghostBorderHover = Color(0x26F5F4EF); // rgba(245, 244, 239, 0.15)
  static const Color frostedGlass = Color(0xA6161514); // rgba(22, 21, 20, 0.65)
  static const Color frostedOverlay = Color(0x08F5F4EF); // rgba(245, 244, 239, 0.03)

  // Primary System Colors
  static const Color primary = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFF30312E);
  static const Color primaryContainer = Color(0xFFE3E3DE);
  static const Color onPrimaryContainer = Color(0xFF646561);
  static const Color inversePrimary = Color(0xFF5E5F5B);

  // Secondary Accents
  static const Color secondary = Color(0xFFE0C298);
  static const Color onSecondary = Color(0xFF402D0F);
  static const Color secondaryContainer = Color(0xFF584323);
  static const Color onSecondaryContainer = Color(0xFFCEB188);

  // Tertiary & Muted Neutrals
  static const Color tertiary = Color(0xFFFFFFFF);
  static const Color onTertiary = Color(0xFF32302D);
  static const Color tertiaryContainer = Color(0xFFE7E1DD);
  static const Color onTertiaryContainer = Color(0xFF676460);
  static const Color milledCharcoal = Color(0xFF2A2825);
  static const Color warmTaupe = Color(0xFF161514);

  // Error & Status
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // Fixed Tones
  static const Color primaryFixed = Color(0xFFE3E3DE);
  static const Color primaryFixedDim = Color(0xFFC7C7C2);
  static const Color onPrimaryFixed = Color(0xFF1B1C19);
  static const Color onPrimaryFixedVariant = Color(0xFF464744);
  static const Color secondaryFixed = Color(0xFFFEDEB2);
  static const Color secondaryFixedDim = Color(0xFFE0C298);
  static const Color onSecondaryFixed = Color(0xFF281800);
  static const Color onSecondaryFixedVariant = Color(0xFF584323);
  static const Color tertiaryFixed = Color(0xFFE7E1DD);
  static const Color tertiaryFixedDim = Color(0xFFCBC6C1);
  static const Color onTertiaryFixed = Color(0xFF1D1B19);
  static const Color onTertiaryFixedVariant = Color(0xFF494643);

  // Background
  static const Color background = Color(0xFF131314);
  static const Color onBackground = Color(0xFFE5E2E3);
}

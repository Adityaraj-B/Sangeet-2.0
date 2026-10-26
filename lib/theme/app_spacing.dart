import 'package:flutter/material.dart';

/// Atelier Acoustique Spacing System
/// Derived from DESIGN.md specification.
abstract final class AppSpacing {
  // Spacing Units
  static const double xs = 4.0; // 0.25rem (space-xs)
  static const double sm = 8.0; // 0.5rem (space-sm)
  static const double md = 16.0; // 1rem (space-md)
  static const double lg = 32.0; // 2rem (space-lg)
  static const double xl = 56.0; // 3.5rem (space-xl)

  // Gutters
  static const double gutterDesktop = 24.0; // 1.5rem
  static const double gutterTablet = 20.0;
  static const double gutterMobile = 16.0; // 1rem (gutter-sm)

  // Canvas Outer Margins
  static const double marginDesktop = 48.0; // 3rem (margin)
  static const double marginTablet = 32.0;
  static const double marginMobile = 20.0; // 1.25rem (margin-sm)

  // Minimum Touch Target
  static const double minTouchTarget = 44.0;

  // Max Viewport Width
  static const double maxViewportWidth = 1440.0;

  // Empty Spacers (Height)
  static const Widget vGapXs = SizedBox(height: xs);
  static const Widget vGapSm = SizedBox(height: sm);
  static const Widget vGapMd = SizedBox(height: md);
  static const Widget vGapLg = SizedBox(height: lg);
  static const Widget vGapXl = SizedBox(height: xl);

  // Empty Spacers (Width)
  static const Widget hGapXs = SizedBox(width: xs);
  static const Widget hGapSm = SizedBox(width: sm);
  static const Widget hGapMd = SizedBox(width: md);
  static const Widget hGapLg = SizedBox(width: lg);
  static const Widget hGapXl = SizedBox(width: xl);

  // Responsive Margin Getter using MediaQuery
  static double responsiveMargin(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return marginDesktop;
    if (width >= 768) return marginTablet;
    return marginMobile;
  }

  // Responsive Gutter Getter using MediaQuery
  static double responsiveGutter(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return gutterDesktop;
    if (width >= 768) return gutterTablet;
    return gutterMobile;
  }
}

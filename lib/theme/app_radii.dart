import 'package:flutter/material.dart';

/// Atelier Acoustique Corner Radii
/// Derived from DESIGN.md specification.
/// Form language echoes precision-machined audio components:
/// sharp, structural, and softly chamfered.
abstract final class AppRadii {
  static const double sm = 2.0; // 0.125rem
  static const double defaultValue = 4.0; // 0.25rem
  static const double md = 6.0; // 0.375rem
  static const double lg = 8.0; // 0.5rem
  static const double xl = 12.0; // 0.75rem
  static const double full = 9999.0; // 50% circle for rotational dials/LEDs

  // BorderRadius helpers
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusDefault = BorderRadius.all(Radius.circular(defaultValue));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(full));
}

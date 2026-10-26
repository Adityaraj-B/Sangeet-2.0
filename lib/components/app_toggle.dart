import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Atelier Acoustique Physical-Toggle Switch
/// Rectangular capsule housing a sliding square indicator.
/// - Inactive: muted charcoal background and indicator.
/// - Active: delicate gold indicator (#C5A880) with soft ambient highlight.
class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    const double width = 48.0;
    const double height = 24.0;
    const double indicatorSize = 18.0;
    const double padding = 3.0;

    final toggle = GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: value ? const Color(0x33C5A880) : AppColors.surfaceContainerLowest,
          borderRadius: AppRadii.radiusSm,
          border: Border.all(
            color: value ? AppColors.secondaryAccent : AppColors.ghostBorderSubtle,
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: value ? width - indicatorSize - padding - 2 : padding,
              child: Container(
                width: indicatorSize,
                height: indicatorSize,
                decoration: BoxDecoration(
                  color: value ? AppColors.secondaryAccent : AppColors.milledCharcoal,
                  borderRadius: AppRadii.radiusSm,
                  boxShadow: value
                      ? [
                          BoxShadow(
                            color: AppColors.secondaryAccent.withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (label == null) return toggle;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: AppRadii.radiusDefault,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            toggle,
            AppSpacing.hGapSm,
            Text(
              label!.toUpperCase(),
              style: AppTypography.labelSm(
                color: value ? AppColors.primaryText : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Atelier Acoustique Precision Square Checkbox
/// Square checkbox (4px radius).
/// Checked state reveals a microscopic gold dot (calibration pin)
/// rather than a standard checkmark.
class AppCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 20.0;

    final box = GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: value ? const Color(0x1AF5F4EF) : AppColors.surfaceContainerLowest,
          borderRadius: AppRadii.radiusDefault,
          border: Border.all(
            color: value ? AppColors.secondaryAccent : AppColors.ghostBorderSubtle,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: value
            ? Container(
                width: 6.0,
                height: 6.0,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryAccent,
                      blurRadius: 3,
                    ),
                  ],
                ),
              )
            : null,
      ),
    );

    if (label == null) return box;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: AppRadii.radiusDefault,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            box,
            AppSpacing.hGapSm,
            Text(
              label!.toUpperCase(),
              style: AppTypography.labelSm(
                color: value ? AppColors.primaryText : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

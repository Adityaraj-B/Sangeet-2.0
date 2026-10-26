import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Atelier Acoustique Precision Chip / Filter Badge
/// Strict architectural rectangular shape (4px corner radius; no pills).
/// - Inactive: dark surface with subtle border.
/// - Active: border turns to delicate gold (#C5A880) with ivory text.
class AppChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;
  final Widget? leading;

  const AppChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.onSelected,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected != null ? () => onSelected!(!isSelected) : null,
      borderRadius: AppRadii.radiusDefault,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0x1AF5F4EF) // subtle interior highlight
              : const Color(0x0FF5F4EF), // rgba(245, 244, 239, 0.06)
          borderRadius: AppRadii.radiusDefault,
          border: Border.all(
            color: isSelected ? AppColors.secondaryAccent : AppColors.ghostBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              AppSpacing.hGapXs,
            ],
            Text(
              label.toUpperCase(),
              style: AppTypography.labelSm(
                color: isSelected ? AppColors.primaryText : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

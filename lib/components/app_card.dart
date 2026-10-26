import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Atelier Acoustique Frosted Control Deck / Card
/// Implements frosted acrylic glassmorphism (24px Gaussian blur),
/// 1px ghost perimeter outline, and spacious negative space padding.
class AppCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsets? padding;
  final bool isActive;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding,
    this.isActive = false,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (title != null || trailing != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Text(
                      title!.toUpperCase(),
                      style: AppTypography.labelMd(
                        color: isActive ? AppColors.secondaryAccent : AppColors.primaryText,
                      ),
                    ),
                  if (subtitle != null) ...[
                    AppSpacing.vGapXs,
                    Text(
                      subtitle!,
                      style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
              ?trailing,
            ],
          ),
          AppSpacing.vGapMd,
          const Divider(color: AppColors.ghostBorder, height: 1),
          AppSpacing.vGapMd,
          child,
        ],
      );
    }

    final card = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xB2100F0E), // rgba(16, 15, 14, 0.70)
        borderRadius: AppRadii.radiusDefault,
        border: Border.all(
          color: isActive ? AppColors.ghostBorderActive : const Color(0x12F5F4EF), // 0.07 opacity
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: content,
    );

    return ClipRRect(
      borderRadius: AppRadii.radiusDefault,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: AppRadii.radiusDefault,
                child: card,
              )
            : card,
      ),
    );
  }
}

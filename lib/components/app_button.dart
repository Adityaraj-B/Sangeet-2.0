import 'package:flutter/material.dart';
import '../theme/theme.dart';

enum AppButtonVariant { primary, ghost }

/// Atelier Acoustique Precision Button
/// Complies with DESIGN.md:
/// - Primary: Cashmere cream background, warm obsidian text, 4px corner radius. Flush, zero shadow.
/// - Ghost / Minimalist: Transparent background, 1px perimeter border, transitions to delicate gold on hover/press.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool isMono;
  final double? width;
  final EdgeInsets? padding;

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isMono = false,
    this.width,
    this.padding,
  }) : variant = AppButtonVariant.primary;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isMono = true,
    this.width,
    this.padding,
  }) : variant = AppButtonVariant.ghost;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null;

    final TextStyle textStyle = widget.isMono
        ? AppTypography.labelMd(
            color: widget.variant == AppButtonVariant.primary
                ? AppColors.neutralCanvas
                : (_isHovered || _isPressed
                    ? AppColors.secondaryAccent
                    : AppColors.primaryText),
          )
        : AppTypography.bodySm(
            color: widget.variant == AppButtonVariant.primary
                ? AppColors.neutralCanvas
                : (_isHovered || _isPressed
                    ? AppColors.secondaryAccent
                    : AppColors.primaryText),
          ).copyWith(fontWeight: FontWeight.w600);

    Color backgroundColor;
    Border? border;

    if (widget.variant == AppButtonVariant.primary) {
      if (!isEnabled) {
        backgroundColor = AppColors.surfaceContainerHigh;
      } else if (_isPressed) {
        backgroundColor = const Color(0xFFE2E0D8);
      } else if (_isHovered) {
        backgroundColor = Colors.white;
      } else {
        backgroundColor = AppColors.primaryText;
      }
      border = null;
    } else {
      // Ghost variant
      if (_isHovered || _isPressed) {
        backgroundColor = const Color(0x0AF5F4EF); // rgba(245, 244, 239, 0.04)
        border = Border.all(color: AppColors.secondaryAccent, width: 1);
      } else {
        backgroundColor = Colors.transparent;
        border = Border.all(color: AppColors.ghostBorderHover, width: 1);
      }
    }

    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
          padding: widget.padding ??
              const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppRadii.radiusDefault,
            border: border,
          ),
          child: Row(
            mainAxisSize: widget.width == null ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                IconTheme(
                  data: IconThemeData(
                    size: 16,
                    color: widget.variant == AppButtonVariant.primary
                        ? AppColors.neutralCanvas
                        : (_isHovered || _isPressed
                            ? AppColors.secondaryAccent
                            : AppColors.primaryText),
                  ),
                  child: widget.icon!,
                ),
                AppSpacing.hGapSm,
              ],
              Text(
                widget.label,
                style: textStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

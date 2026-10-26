import 'package:flutter/material.dart';
import '../theme/theme.dart';

enum AppTextFieldVariant { boxed, underline }

/// Atelier Acoustique Precision Input Field
/// Understated boxed surface or bottom-line with 1px hairline border,
/// subtle gold focus caret/glow, cashmere cream text, and subdued placeholder.
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final AppTextFieldVariant variant;
  final bool autofocus;

  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.variant = AppTextFieldVariant.boxed,
    this.autofocus = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = widget.variant == AppTextFieldVariant.boxed
        ? OutlineInputBorder(
            borderRadius: AppRadii.radiusDefault,
            borderSide: BorderSide(
              color: _isFocused ? AppColors.secondaryAccent : AppColors.ghostBorderSubtle,
              width: 1,
            ),
          )
        : UnderlineInputBorder(
            borderSide: BorderSide(
              color: _isFocused ? AppColors.secondaryAccent : AppColors.ghostBorderSubtle,
              width: 1,
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!.toUpperCase(),
            style: AppTypography.labelSm(
              color: _isFocused ? AppColors.secondaryAccent : AppColors.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapXs,
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: widget.variant == AppTextFieldVariant.boxed
              ? BoxDecoration(
                  borderRadius: AppRadii.radiusDefault,
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: AppColors.secondaryAccent.withValues(alpha: 0.15),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                )
              : null,
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            cursorColor: AppColors.secondaryAccent,
            style: AppTypography.bodyMd(color: AppColors.primaryText),
            decoration: InputDecoration(
              isDense: true,
              filled: widget.variant == AppTextFieldVariant.boxed,
              fillColor: const Color(0x0FF5F4EF), // rgba(245, 244, 239, 0.06)
              hintText: widget.hintText,
              hintStyle: AppTypography.bodyMd(
                color: const Color(0x4DF5F4EF), // rgba(245, 244, 239, 0.3)
              ),
              prefixIcon: widget.prefixIcon != null
                  ? IconTheme(
                      data: IconThemeData(
                        size: 18,
                        color: _isFocused
                            ? AppColors.secondaryAccent
                            : AppColors.onSurfaceVariant,
                      ),
                      child: widget.prefixIcon!,
                    )
                  : null,
              suffixIcon: widget.suffixIcon != null
                  ? IconTheme(
                      data: IconThemeData(
                        size: 18,
                        color: _isFocused
                            ? AppColors.secondaryAccent
                            : AppColors.onSurfaceVariant,
                      ),
                      child: widget.suffixIcon!,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 4,
              ),
              enabledBorder: border,
              focusedBorder: border,
              border: border,
            ),
          ),
        ),
      ],
    );
  }
}

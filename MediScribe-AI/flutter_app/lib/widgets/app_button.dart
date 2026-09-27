import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/typography.dart';

/// Premium button with press-scale micro-animation.
/// Variants: primary, secondary, danger, ghost, outline.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool isLoading;
  final bool isFullWidth;
  final _ButtonVariant _variant;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.padding,
    this.height,
  }) : _variant = _ButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.padding,
    this.height,
  }) : _variant = _ButtonVariant.secondary;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.padding,
    this.height,
  }) : _variant = _ButtonVariant.danger;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.height,
  }) : _variant = _ButtonVariant.ghost;

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.padding,
    this.height,
  }) : _variant = _ButtonVariant.outline;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = onPressed == null || isLoading;

    Widget button = _buildButton(context, isDark, isDisabled);

    if (isFullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button
        .animate(target: isDisabled ? 0 : 1)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(0.97, 0.97),
          duration: 80.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildButton(BuildContext context, bool isDark, bool isDisabled) {
    final content = _buildContent(isDark);
    final effectivePadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md + 2,
        );

    switch (_variant) {
      case _ButtonVariant.primary:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDisabled
                ? (isDark ? AppColors.borderDark : AppColors.borderLight)
                : (isDark ? AppColors.primaryTealLight : AppColors.primaryTeal),
            foregroundColor: isDark ? AppColors.backgroundDark : Colors.white,
            padding: effectivePadding,
            minimumSize: Size(0, height ?? 52),
            elevation: 0,
          ),
          child: content,
        );

      case _ButtonVariant.secondary:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark
                ? AppColors.primaryTeal.withValues(alpha: 0.15)
                : AppColors.navIndicatorLight,
            foregroundColor: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
            padding: effectivePadding,
            minimumSize: Size(0, height ?? 52),
            elevation: 0,
          ),
          child: content,
        );

      case _ButtonVariant.danger:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            padding: effectivePadding,
            minimumSize: Size(0, height ?? 52),
            elevation: 0,
          ),
          child: content,
        );

      case _ButtonVariant.ghost:
        return TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
            padding: effectivePadding,
            minimumSize: Size(0, height ?? 44),
          ),
          child: content,
        );

      case _ButtonVariant.outline:
        return OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
            side: BorderSide(
              color: isDisabled
                  ? AppColors.borderLight
                  : (isDark ? AppColors.primaryTealLight : AppColors.primaryTeal),
              width: 1.5,
            ),
            padding: effectivePadding,
            minimumSize: Size(0, height ?? 52),
          ),
          child: content,
        );
    }
  }

  Widget _buildContent(bool isDark) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            _variant == _ButtonVariant.primary || _variant == _ButtonVariant.danger
                ? Colors.white
                : (isDark ? AppColors.primaryTealLight : AppColors.primaryTeal),
          ),
        ),
      );
    }

    final List<Widget> children = [];
    if (prefixIcon != null) {
      children.add(Icon(prefixIcon, size: 18));
      children.add(AppSpacing.hGap8);
    }
    children.add(
      Text(
        label,
        style: AppTypography.titleSmall.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
    if (suffixIcon != null) {
      children.add(AppSpacing.hGap8);
      children.add(Icon(suffixIcon, size: 18));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}

enum _ButtonVariant { primary, secondary, danger, ghost, outline }

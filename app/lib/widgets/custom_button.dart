import 'package:flutter/material.dart';
import 'app_button.dart';

/// A convenience wrapper around [AppButton] that preserves the `CustomButton` name
/// for backwards compatibility with any code that imports this widget.
///
/// Prefer using [AppButton.primary], [AppButton.secondary], etc. directly for new code.
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final bool isDanger;
  final bool isOutline;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.isDanger = false,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isDanger) {
      return AppButton.danger(
        label: label,
        onPressed: onPressed,
        isLoading: isLoading,
        isFullWidth: isFullWidth,
        prefixIcon: icon,
      );
    }
    if (isOutline) {
      return AppButton.outline(
        label: label,
        onPressed: onPressed,
        isLoading: isLoading,
        isFullWidth: isFullWidth,
        prefixIcon: icon,
      );
    }
    return AppButton.primary(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      prefixIcon: icon,
    );
  }
}

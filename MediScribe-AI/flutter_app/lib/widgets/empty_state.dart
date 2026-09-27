import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/typography.dart';
import 'app_button.dart';

/// Premium empty state widget with animated icon, title, message, and optional CTA.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final Color? iconBgColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor = iconColor ?? AppColors.primaryTeal;
    final effectiveIconBg = iconBgColor ??
        (isDark ? AppColors.navIndicatorDark : AppColors.navIndicatorLight);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: effectiveIconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: effectiveIconColor),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.04, 1.04),
                  duration: 2400.ms,
                  curve: Curves.easeInOut,
                ),

            AppSpacing.vGap28,

            Text(
              title,
              style: AppTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 400.ms),

            AppSpacing.vGap12,

            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 350.ms, duration: 400.ms),

            if (actionLabel != null && onAction != null) ...[
              AppSpacing.vGap32,
              AppButton.primary(
                label: actionLabel!,
                onPressed: onAction,
                isFullWidth: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.md,
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 400.ms)
                  .slideY(begin: 0.3, end: 0, delay: 500.ms, duration: 400.ms),
            ],
          ],
        ),
      ),
    );
  }
}

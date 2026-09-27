import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';

/// Shimmer skeleton loader for premium loading states.
/// Use `SkeletonBox`, `SkeletonText`, `SkeletonAvatar`, `SkeletonCard`, etc.
class SkeletonLoader extends StatelessWidget {
  final Widget child;

  const SkeletonLoader({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase,
      highlightColor: isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlight,
      period: const Duration(milliseconds: 1200),
      child: child,
    );
  }
}

/// Rectangular skeleton placeholder box
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase,
        borderRadius: borderRadius ?? AppSpacing.borderRadiusSm,
      ),
    );
  }
}

/// Text line skeleton
class SkeletonText extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonText({super.key, required this.width, this.height = 14});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase,
        borderRadius: AppSpacing.borderRadiusSm,
      ),
    );
  }
}

/// Circular avatar skeleton
class SkeletonAvatar extends StatelessWidget {
  final double size;

  const SkeletonAvatar({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Full dashboard skeleton for the initial load
class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const SkeletonAvatar(size: 52),
                AppSpacing.hGap12,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonText(width: 140),
                    AppSpacing.vGap8,
                    const SkeletonText(width: 100, height: 20),
                  ],
                ),
              ],
            ),
            AppSpacing.vGap24,
            // Stat Cards
            Row(
              children: [
                Expanded(child: SkeletonBox(width: double.infinity, height: 100, borderRadius: AppSpacing.borderRadiusLg)),
                AppSpacing.hGap12,
                Expanded(child: SkeletonBox(width: double.infinity, height: 100, borderRadius: AppSpacing.borderRadiusLg)),
                AppSpacing.hGap12,
                Expanded(child: SkeletonBox(width: double.infinity, height: 100, borderRadius: AppSpacing.borderRadiusLg)),
              ],
            ),
            AppSpacing.vGap24,
            // Section title
            const SkeletonText(width: 160, height: 18),
            AppSpacing.vGap12,
            SkeletonBox(width: double.infinity, height: 120, borderRadius: AppSpacing.borderRadiusLg),
            AppSpacing.vGap24,
            const SkeletonText(width: 160, height: 18),
            AppSpacing.vGap12,
            _listItemSkeleton(),
            AppSpacing.vGap12,
            _listItemSkeleton(),
            AppSpacing.vGap12,
            _listItemSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _listItemSkeleton() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Row(
        children: [
          const SkeletonAvatar(size: 44),
          AppSpacing.hGap12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonText(width: 160),
                AppSpacing.vGap8,
                const SkeletonText(width: 100, height: 12),
              ],
            ),
          ),
          const SkeletonBox(width: 60, height: 28),
        ],
      ),
    );
  }
}

/// List item skeleton for medicine/reminder lists
class SkeletonListItem extends StatelessWidget {
  const SkeletonListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: AppSpacing.cardPaddingAll,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        child: Row(
          children: [
            const SkeletonAvatar(size: 44),
            AppSpacing.hGap12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonText(width: 150),
                  AppSpacing.vGap8,
                  const SkeletonText(width: 100, height: 12),
                ],
              ),
            ),
            const SkeletonBox(width: 64, height: 30),
          ],
        ),
      ),
    );
  }
}

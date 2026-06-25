import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/typography.dart';
import '../core/theme/app_theme.dart';
import '../core/routes/app_router.dart';
import '../services/api_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton_loader.dart';

// ==========================================
// Provider: Loads prescriptions from the backend API
// ==========================================
final _prescriptionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getPrescriptions();
});

class PrescriptionResultScreen extends ConsumerWidget {
  const PrescriptionResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prescriptionsAsync = ref.watch(_prescriptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_prescriptionsProvider),
          ),
        ],
      ),
      body: prescriptionsAsync.when(
        loading: () => _buildLoadingState(),
        error: (err, _) => _buildErrorState(err.toString(), ref),
        data: (prescriptions) => prescriptions.isEmpty
            ? EmptyStateWidget(
                icon: Icons.description_rounded,
                title: 'No Prescriptions',
                message:
                    'Scan a prescription to get started. Your OCR results and medical records appear here.',
                actionLabel: 'Scan Now',
                onAction: () => context.push(AppRouter.scan),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(_prescriptionsProvider),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.pageHorizontal,
                            AppSpacing.lg, AppSpacing.pageHorizontal, AppSpacing.lg),
                        child: SectionHeader(title: '${prescriptions.length} Records'),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pageHorizontal, 0, AppSpacing.pageHorizontal, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _buildPrescriptionCard(
                              prescriptions[i], isDark, i, context),
                          childCount: prescriptions.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'scan_fab',
        onPressed: () => context.push(AppRouter.scan),
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text('Scan Prescription'),
      )
          .animate()
          .fadeIn(delay: 300.ms)
          .slideY(begin: 0.4, end: 0, delay: 300.ms),
    );
  }

  Widget _buildLoadingState() {
    return SkeletonLoader(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            SkeletonBox(width: double.infinity, height: 80, borderRadius: AppSpacing.borderRadiusLg),
            const SizedBox(height: AppSpacing.md),
            SkeletonBox(width: double.infinity, height: 80, borderRadius: AppSpacing.borderRadiusLg),
            const SizedBox(height: AppSpacing.md),
            SkeletonBox(width: double.infinity, height: 80, borderRadius: AppSpacing.borderRadiusLg),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.danger),
            const SizedBox(height: AppSpacing.lg),
            Text('Failed to load prescriptions',
                style: AppTypography.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(error,
                style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(_prescriptionsProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard(
      Map<String, dynamic> data, bool isDark, int index, BuildContext context) {
    final date = data['created_at'] as String? ?? '—';
    final medicineCount = (data['medicines'] as List?)?.length ?? 0;
    final status = data['status'] as String? ?? 'active';

    final statusColor = status == 'active' ? AppColors.success : AppColors.textSecondaryLight;
    final statusBg = status == 'active' ? AppColors.successLight : const Color(0xFFF1F5F9);

    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceCardDark : Colors.white,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          boxShadow: isDark ? AppTheme.premiumShadowDark : AppTheme.premiumShadowLight,
        ),
        child: Column(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
              ),
            ),
            Padding(
              padding: AppSpacing.cardPaddingAll,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.navIndicatorDark : AppColors.navIndicatorLight,
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: const Icon(Icons.description_rounded,
                        color: AppColors.primaryTeal, size: 24),
                  ),
                  AppSpacing.hGap12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Prescription #${index + 1}',
                            style: AppTypography.titleSmall
                                .copyWith(fontWeight: FontWeight.w700)),
                        AppSpacing.vGap4,
                        Text(
                          '$medicineCount medicine${medicineCount != 1 ? 's' : ''} · $date',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: AppSpacing.borderRadiusRound,
                    ),
                    child: Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: AppTypography.labelMedium.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(delay: (index * 70).ms)
          .fadeIn(duration: 350.ms)
          .slideY(begin: 0.1, end: 0, duration: 350.ms),
    );
  }
}

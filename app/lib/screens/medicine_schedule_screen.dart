import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/typography.dart';
import '../core/theme/app_theme.dart';
import '../services/reminder_provider.dart';
import '../widgets/empty_state.dart';

class MedicineScheduleScreen extends ConsumerWidget {
  const MedicineScheduleScreen({super.key});

  static const List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(reminderListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now().weekday; // 1=Mon..7=Sun

    if (reminders.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Weekly Schedule')),
        body: EmptyStateWidget(
          icon: Icons.calendar_month_rounded,
          title: 'No Schedule Yet',
          message: 'Add medication reminders to see your weekly schedule here.',
          actionLabel: 'Add Reminder',
          onAction: () => context.pop(),
        ),
      );
    }

    final totalActive = reminders.where((r) => r.isActive).length;
    final adherencePct = reminders.isNotEmpty
        ? ((totalActive / reminders.length) * 100).toInt()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Schedule'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Adherence card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal, AppSpacing.lg, AppSpacing.pageHorizontal, 0),
              child: _buildAdherenceCard(adherencePct, totalActive, reminders.length, isDark),
            ),
          ),

          // Day strip header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal, AppSpacing.xl, AppSpacing.pageHorizontal, AppSpacing.lg),
              child: Row(
                children: List.generate(7, (i) {
                  final dayNum = i + 1;
                  final isToday = dayNum == today;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 6 ? 6 : 0),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isToday
                            ? const Color(0xFF6C63FF)
                            : (isDark ? AppColors.surfaceCardDark : Colors.white),
                        borderRadius: AppSpacing.borderRadiusMd,
                        border: Border.all(
                          color: isToday
                              ? const Color(0xFF6C63FF)
                              : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _days[i],
                            style: AppTypography.labelMedium.copyWith(
                              color: isToday
                                  ? Colors.white
                                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                          AppSpacing.vGap4,
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _hasMedsOnDay(reminders, dayNum)
                                  ? (isToday ? Colors.white : const Color(0xFF6C63FF))
                                  : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Day-by-day list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal, 0, AppSpacing.pageHorizontal, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final dayNum = i + 1;
                  final dayReminders = reminders
                      .where((r) =>
                          r.isActive &&
                          (r.daysOfWeek.isEmpty || r.daysOfWeek.contains(dayNum)))
                      .toList();

                  if (dayReminders.isEmpty) return const SizedBox.shrink();

                  return _buildDaySection(dayNum, dayReminders, isDark, dayNum == today, i)
                      .animate(delay: (i * 60).ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.1, end: 0, duration: 350.ms);
                },
                childCount: 7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasMedsOnDay(List reminders, int dayNum) {
    return reminders.any((r) =>
        r.isActive && (r.daysOfWeek.isEmpty || r.daysOfWeek.contains(dayNum)));
  }

  Widget _buildAdherenceCard(int pct, int active, int total, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: AppTheme.tealGlowShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Adherence',
                    style: AppTypography.bodyMedium
                        .copyWith(color: Colors.white.withValues(alpha: 0.75))),
                AppSpacing.vGap8,
                Text('$pct%',
                    style: AppTypography.displayMedium.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                AppSpacing.vGap4,
                Text('$active of $total reminders active',
                    style: AppTypography.bodySmall
                        .copyWith(color: Colors.white.withValues(alpha: 0.65))),
                AppSpacing.vGap16,
                ClipRRect(
                  borderRadius: AppSpacing.borderRadiusRound,
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      pct > 70 ? AppColors.success : AppColors.warning,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.hGap24,
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today_rounded,
                color: Colors.white, size: 34),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySection(int dayNum, List reminders, bool isDark, bool isToday, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: isToday
                      ? const Color(0xFF6C63FF)
                      : (isDark ? AppColors.surfaceCardDark : const Color(0xFFF1F5F9)),
                  borderRadius: AppSpacing.borderRadiusRound,
                ),
                child: Text(
                  isToday ? 'Today · ${_days[dayNum - 1]}' : _days[dayNum - 1],
                  style: AppTypography.labelLarge.copyWith(
                    color: isToday
                        ? Colors.white
                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AppSpacing.hGap12,
              Expanded(
                child: Divider(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ],
          ),
        ),
        ...reminders.asMap().entries.map((e) {
          final r = e.value;
          final hour = r.time.hourOfPeriod == 0 ? 12 : r.time.hourOfPeriod;
          final period = r.time.period == DayPeriod.am ? 'AM' : 'PM';
          final minute = r.time.minute.toString().padLeft(2, '0');
          final timeStr = '$hour:$minute $period';

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: AppSpacing.edgeInsetsCard,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceCardDark : Colors.white,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.10),
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: const Icon(Icons.medication_rounded,
                      color: const Color(0xFF6C63FF), size: 22),
                ),
                AppSpacing.hGap12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.medicineName,
                          style: AppTypography.titleSmall
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text(r.dosage,
                          style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
                Text(
                  timeStr,
                  style: AppTypography.titleSmall.copyWith(
                    color: const Color(0xFF6C63FF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }),
        AppSpacing.vGap8,
      ],
    );
  }
}

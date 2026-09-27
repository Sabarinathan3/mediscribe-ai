import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/typography.dart';
import '../core/theme/app_theme.dart';
import '../models/reminder_model.dart';
import '../services/reminder_provider.dart';

/// Premium reminder card with time display, day-of-week pills, active toggle, swipe-to-delete.
class ReminderCard extends ConsumerWidget {
  final ReminderModel reminder;
  final VoidCallback? onEdit;
  final int animationIndex;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onEdit,
    this.animationIndex = 0,
  });

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = reminder.isActive;
    final dayNames = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};

    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        alignment: Alignment.centerRight,
        padding: AppSpacing.edgeInsetsHorizontal24,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
            AppSpacing.vGap4,
            Text('Delete', style: AppTypography.labelMedium.copyWith(color: Colors.white)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Reminder'),
            content: Text('Remove reminder for ${reminder.medicineName}?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ) ??
            false;
      },
      onDismissed: (_) {
        ref.read(reminderProvider.notifier).deleteReminder(reminder.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${reminder.medicineName} reminder deleted'),
            backgroundColor: AppColors.danger,
          ),
        );
      },
      child: AnimatedOpacity(
        duration: 300.ms,
        opacity: isActive ? 1.0 : 0.55,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(
              color: isActive
                  ? (isDark
                      ? AppColors.primaryTeal.withValues(alpha: 0.4)
                      : AppColors.primaryTeal.withValues(alpha: 0.25))
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            boxShadow: isDark ? AppTheme.premiumShadowDark : AppTheme.premiumShadowLight,
          ),
          child: Padding(
            padding: AppSpacing.cardPaddingAll,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Alarm icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isDark ? AppColors.navIndicatorDark : AppColors.navIndicatorLight)
                        : (isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9)),
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: Icon(
                    isActive ? Icons.alarm_on_rounded : Icons.alarm_off_rounded,
                    color: isActive
                        ? (isDark ? AppColors.primaryTealLight : AppColors.primaryTeal)
                        : AppColors.textSecondaryLight,
                    size: 26,
                  ),
                ),
                AppSpacing.hGap12,

                // Center: Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.medicineName,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppSpacing.vGap4,
                      Text(
                        '${reminder.dosage} · ${_formatTime(reminder.time)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: isActive
                              ? (isDark ? AppColors.primaryTealLight : AppColors.primaryTeal)
                              : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      AppSpacing.vGap8,
                      // Day pills
                      Wrap(
                        spacing: 4,
                        children: reminder.daysOfWeek.isEmpty
                            ? [_dayPill('Daily', isActive, isDark)]
                            : reminder.daysOfWeek
                                .map((d) => _dayPill(dayNames[d] ?? '?', isActive, isDark))
                                .toList(),
                      ),
                    ],
                  ),
                ),
                AppSpacing.hGap8,

                // Right: Toggle + Edit
                Column(
                  children: [
                    Switch.adaptive(
                      value: isActive,
                      onChanged: (_) {
                        ref.read(reminderProvider.notifier).toggleReminderActive(reminder.id);
                      },
                    ),
                    if (onEdit != null)
                      GestureDetector(
                        onTap: onEdit,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: (animationIndex * 60).ms)
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }

  Widget _dayPill(String label, bool isActive, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? AppColors.navIndicatorDark : AppColors.navIndicatorLight)
            : (isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9)),
        borderRadius: AppSpacing.borderRadiusRound,
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: isActive
              ? (isDark ? AppColors.primaryTealLight : AppColors.primaryTeal)
              : AppColors.textSecondaryLight,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

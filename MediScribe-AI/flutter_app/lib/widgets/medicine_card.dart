import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/typography.dart';
import '../core/theme/app_theme.dart';
import '../models/medicine_model.dart';

/// Premium medicine card with dosage chips, interaction badge, and expand animation.
class MedicineCard extends StatefulWidget {
  final MedicineModel medicine;
  final VoidCallback? onAddReminder;
  final VoidCallback? onTap;
  final bool showInteractionBadge;
  final int animationIndex;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.onAddReminder,
    this.onTap,
    this.showInteractionBadge = true,
    this.animationIndex = 0,
  });

  @override
  State<MedicineCard> createState() => _MedicineCardState();
}

class _MedicineCardState extends State<MedicineCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasInteractions = widget.medicine.interactions.isNotEmpty;
    final hasCritical = widget.medicine.interactions.any((i) => i.severity == 'critical');

    return GestureDetector(
      onTap: widget.onTap ?? () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: 280.ms,
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: hasCritical && widget.showInteractionBadge
                ? AppColors.danger.withValues(alpha: 0.5)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          boxShadow: isDark ? AppTheme.premiumShadowDark : AppTheme.premiumShadowLight,
        ),
        child: Column(
          children: [
            // Accent strip
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: hasCritical && widget.showInteractionBadge
                    ? AppColors.alertGradient
                    : AppColors.primaryGradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLg),
                ),
              ),
            ),

            Padding(
              padding: AppSpacing.cardPaddingAll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Medicine icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.navIndicatorDark
                              : AppColors.navIndicatorLight,
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                        child: Icon(
                          Icons.medication_rounded,
                          color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
                          size: 22,
                        ),
                      ),
                      AppSpacing.hGap12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.medicine.name,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            AppSpacing.vGap4,
                            Text(
                              widget.medicine.dosage,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Interaction badge
                      if (hasInteractions && widget.showInteractionBadge)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: hasCritical ? AppColors.dangerLight : AppColors.warningLight,
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                          child: Text(
                            hasCritical ? '⚠️ Critical' : '⚠️ Warning',
                            style: AppTypography.labelMedium.copyWith(
                              color: hasCritical ? AppColors.danger : AppColors.warning,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),

                  AppSpacing.vGap12,

                  // Info chips
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _infoChip(
                        Icons.schedule_rounded,
                        widget.medicine.frequency,
                        isDark,
                      ),
                      _infoChip(
                        Icons.calendar_today_rounded,
                        widget.medicine.duration,
                        isDark,
                      ),
                      if (widget.medicine.instruction.isNotEmpty)
                        _infoChip(
                          Icons.info_outline_rounded,
                          widget.medicine.instruction,
                          isDark,
                        ),
                    ],
                  ),

                  // Expanded section
                  AnimatedSize(
                    duration: 280.ms,
                    curve: Curves.easeInOut,
                    child: _isExpanded
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSpacing.vGap12,
                              const Divider(height: 1),
                              AppSpacing.vGap12,
                              if (widget.medicine.translatedInstruction != null &&
                                  widget.medicine.translatedInstruction!.isNotEmpty)
                                _expandedRow(
                                  Icons.translate_rounded,
                                  'Translated',
                                  widget.medicine.translatedInstruction!,
                                  isDark,
                                ),
                              if (hasInteractions) ...[
                                AppSpacing.vGap8,
                                Text(
                                  'Drug Interactions',
                                  style: AppTypography.titleSmall.copyWith(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                AppSpacing.vGap8,
                                ...widget.medicine.interactions.map(
                                  (i) => Container(
                                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                                    padding: AppSpacing.edgeInsetsAll12,
                                    decoration: BoxDecoration(
                                      color: i.severity == 'critical'
                                          ? AppColors.dangerLight
                                          : AppColors.warningLight,
                                      borderRadius: AppSpacing.borderRadiusMd,
                                    ),
                                    child: Text(
                                      '${i.sourceDrug} + ${i.targetDrug}: ${i.descriptionEn}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: i.severity == 'critical'
                                            ? AppColors.danger
                                            : AppColors.warning,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (widget.onAddReminder != null) ...[
                                AppSpacing.vGap12,
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: widget.onAddReminder,
                                    icon: const Icon(Icons.alarm_add_rounded, size: 16),
                                    label: const Text('Add Reminder'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                      minimumSize: const Size(0, 40),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Expand chevron
                  if (widget.onTap == null)
                    Center(
                      child: AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: 280.ms,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (widget.animationIndex * 80).ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.15, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _infoChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _expandedRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          AppSpacing.hGap8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.labelMedium.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                AppSpacing.vGap2,
                Text(value,
                    style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

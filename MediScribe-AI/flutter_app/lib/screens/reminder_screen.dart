import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/typography.dart';
import '../models/reminder_model.dart';
import '../services/reminder_provider.dart';
import '../widgets/reminder_card.dart';
import '../widgets/empty_state.dart';

class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key});

  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(notificationServiceProvider).requestPermissions();
      }
    });
  }

  void _showAddEditSheet([ReminderModel? reminder]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditReminderSheet(reminder: reminder),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(reminderListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = reminders.where((r) => r.isActive).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          if (reminders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: TextButton.icon(
                onPressed: _showAddEditSheet,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
              ),
            ),
        ],
      ),
      body: reminders.isEmpty
          ? EmptyStateWidget(
              icon: Icons.alarm_add_rounded,
              title: 'No Reminders Yet',
              message:
                  'Schedule medication alarms and never miss a dose. Your reminders appear here.',
              actionLabel: 'Add First Reminder',
              onAction: _showAddEditSheet,
            )
          : CustomScrollView(
              slivers: [
                // Summary pill
                SliverToBoxAdapter(
                  child: _buildSummaryPill(active, reminders.length, isDark),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    AppSpacing.lg,
                    AppSpacing.pageHorizontal,
                    120,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => ReminderCard(
                        reminder: reminders[i],
                        animationIndex: i,
                        onEdit: () => _showAddEditSheet(reminders[i]),
                      ),
                      childCount: reminders.length,
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: reminders.isNotEmpty
          ? FloatingActionButton.extended(
              heroTag: 'reminder_fab',
              onPressed: _showAddEditSheet,
              icon: const Icon(Icons.alarm_add_rounded),
              label: const Text('Add Reminder'),
            )
              .animate()
              .fadeIn(delay: 300.ms)
              .slideY(begin: 0.4, end: 0, delay: 300.ms)
          : null,
    );
  }

  Widget _buildSummaryPill(int active, int total, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
        AppSpacing.pageHorizontal,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceCardDark : Colors.white,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: const Icon(Icons.alarm_rounded,
                  color: AppColors.primaryTeal, size: 20),
            ),
            AppSpacing.hGap12,
            Expanded(
              child: Text(
                '$active of $total reminders active',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: active > 0 ? AppColors.successLight : AppColors.dangerLight,
                borderRadius: AppSpacing.borderRadiusRound,
              ),
              child: Text(
                active > 0 ? 'Active' : 'All Off',
                style: AppTypography.labelMedium.copyWith(
                  color: active > 0 ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 350.ms),
    );
  }
}

// ==========================================
// Add/Edit Reminder Bottom Sheet
// ==========================================
class AddEditReminderSheet extends ConsumerStatefulWidget {
  final ReminderModel? reminder;
  const AddEditReminderSheet({super.key, this.reminder});

  @override
  ConsumerState<AddEditReminderSheet> createState() =>
      _AddEditReminderSheetState();
}

class _AddEditReminderSheetState extends ConsumerState<AddEditReminderSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _dosageCtrl;
  late TimeOfDay _time;
  late List<int> _days;

  final _weekdays = [
    {'day': 1, 'label': 'M', 'full': 'Mon'},
    {'day': 2, 'label': 'T', 'full': 'Tue'},
    {'day': 3, 'label': 'W', 'full': 'Wed'},
    {'day': 4, 'label': 'T', 'full': 'Thu'},
    {'day': 5, 'label': 'F', 'full': 'Fri'},
    {'day': 6, 'label': 'S', 'full': 'Sat'},
    {'day': 7, 'label': 'S', 'full': 'Sun'},
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    _nameCtrl = TextEditingController(text: r?.medicineName ?? '');
    _dosageCtrl = TextEditingController(text: r?.dosage ?? '');
    _time = r?.time ?? const TimeOfDay(hour: 8, minute: 0);
    _days = r != null ? List<int>.from(r.daysOfWeek) : [];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final id = widget.reminder?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final r = ReminderModel(
      id: id,
      medicineName: _nameCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim(),
      time: _time,
      daysOfWeek: _days,
      isActive: widget.reminder?.isActive ?? true,
    );
    final notifier = ref.read(reminderProvider.notifier);
    if (widget.reminder != null) {
      notifier.updateReminder(r);
    } else {
      notifier.addReminder(r);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.reminder != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl + bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: AppSpacing.borderRadiusTopXxl,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: AppSpacing.borderRadiusRound,
                  ),
                ),
              ),
              AppSpacing.vGap20,

              Text(
                isEdit ? 'Edit Reminder' : 'New Reminder',
                style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
              ),
              AppSpacing.vGap24,

              // Name field
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name',
                  prefixIcon: Icon(Icons.medication_rounded),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                textInputAction: TextInputAction.next,
              ),
              AppSpacing.vGap16,

              // Dosage field
              TextFormField(
                controller: _dosageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  hintText: 'e.g. 500mg, 1 tablet',
                  prefixIcon: Icon(Icons.science_rounded),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                textInputAction: TextInputAction.done,
              ),
              AppSpacing.vGap24,

              // Time picker
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceCardDark : const Color(0xFFF8FAFC),
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alarm_rounded, color: AppColors.primaryTeal),
                      AppSpacing.hGap12,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Alarm Time',
                              style: AppTypography.labelMedium.copyWith(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                          Text(
                            _time.format(context),
                            style: AppTypography.headlineMedium.copyWith(
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        child: Text('Change',
                            style: AppTypography.labelLarge.copyWith(color: AppColors.primaryTeal)),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.vGap24,

              // Day picker
              Text('Repeat Days',
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
              AppSpacing.vGap12,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _weekdays.map((wd) {
                  final day = wd['day'] as int;
                  final label = wd['label'] as String;
                  final selected = _days.contains(day);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (selected) { _days.remove(day); }
                      else { _days.add(day); }
                    }),
                    child: AnimatedContainer(
                      duration: 180.ms,
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryTeal
                            : (isDark ? AppColors.surfaceCardDark : const Color(0xFFF1F5F9)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? AppColors.primaryTeal : Colors.transparent,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: AppTypography.labelLarge.copyWith(
                          color: selected
                              ? Colors.white
                              : (isDark ? Colors.white60 : Colors.black54),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              AppSpacing.vGap8,
              Text(
                _days.isEmpty
                    ? '🔔 Will repeat every day'
                    : '🔔 Will repeat on ${_days.length} selected days',
                style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              AppSpacing.vGap32,

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(isEdit ? 'Save Changes' : 'Schedule Reminder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

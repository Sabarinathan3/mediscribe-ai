import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/typography.dart';
import '../core/routes/app_router.dart';
import '../services/auth_provider.dart';
import '../services/reminder_provider.dart';
import '../services/prescription_provider.dart';
import '../models/reminder_model.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton_loader.dart';
import 'onboarding_screen.dart'; // Import to reuse BackgroundPatternPainter

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Simple local state tracker for today's medicine compliance actions
  final Map<String, String> _complianceActions = {}; // id -> 'taken' | 'skipped' | 'missed'

  final List<String> _healthTips = [
    'Ensure consistency for blood-pressure meds to avoid rapid level fluctuations.',
    'Drink a full glass of water with your medications to help absorption.',
    'Do not take antibiotics with dairy or grapefruit juice as they can block absorption.',
    'Keep your medicines in a cool, dry place. Avoid hot and humid bathroom cabinets.',
    'If you miss a dose, do not take a double dose. Skip it and take the next dose at schedule.',
    'Always complete your full course of antibiotics even if you feel better.',
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final reminders = ref.watch(reminderListProvider);
    final prescriptionsAsync = ref.watch(prescriptionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userName = authState is Authenticated
        ? authState.user.fullName.split(' ').first
        : 'there';
    
    final activeReminders = reminders.where((r) => r.isActive).toList();

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    final tipIndex = DateTime.now().day % _healthTips.length;
    final dailyTip = _healthTips[tipIndex];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background Painter for premium visual consistency
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: BackgroundPatternPainter(),
              ),
            ),
          ),

          RefreshIndicator(
            color: const Color(0xFF6C63FF),
            onRefresh: () async {
              ref.invalidate(prescriptionsProvider);
              await ref.read(authProvider.notifier).checkAuthStatus();
            },
            child: CustomScrollView(
              slivers: [
                // ─── SliverAppBar ───
                SliverAppBar(
                  expandedHeight: 180,
                  collapsedHeight: 80,
                  pinned: true,
                  backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E1B4B), AppColors.backgroundDark]
                              : [const Color(0xFFEEF0FD), AppColors.backgroundLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$greeting,',
                                        style: AppTypography.bodyLarge.copyWith(
                                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        userName,
                                        style: AppTypography.displayLarge.copyWith(
                                          color: isDark ? Colors.white : const Color(0xFF111827),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 30,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Right Actions: Avatar & Notifications Badge
                                  Row(
                                    children: [
                                      // Notification Bell
                                      Stack(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.notifications_outlined,
                                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                                              size: 26,
                                            ),
                                            onPressed: () => _showNotificationsSheet(context),
                                          ),
                                          if (activeReminders.isNotEmpty)
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                width: 10,
                                                height: 10,
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      // Avatar Container (routes to Profile tab)
                                      GestureDetector(
                                        onTap: () => context.go(AppRouter.profile),
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6C63FF).withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFF6C63FF),
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                              style: const TextStyle(
                                                color: Color(0xFF6C63FF),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ─── Main Content Items ───
                SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),

                    // Prescription Upload Banner
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildUploadBanner(context, isDark),
                    )
                        .animate()
                        .fadeIn(duration: 450.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 24),

                    // Quick Actions Section
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: SectionHeader(title: 'Quick Actions'),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildQuickActionsGrid(context, isDark),
                    ),

                    const SizedBox(height: 28),

                    // Recent Activity Section (parsed prescriptions)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SectionHeader(
                        title: 'Recent Activity',
                        actionLabel: 'View All',
                        onAction: () => context.go(AppRouter.prescriptions),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: prescriptionsAsync.when(
                        loading: () => _buildPrescriptionShimmer(),
                        error: (err, _) => _buildPrescriptionError(err.toString()),
                        data: (list) {
                          if (list.isEmpty) {
                            return _buildPrescriptionEmpty(context, isDark);
                          }
                          // Show top 3 recent prescriptions
                          final recent = list.take(3).toList();
                          return Column(
                            children: recent.map((item) => _buildPrescriptionActivityCard(item, isDark)).toList(),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Today's Medicines checklist
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SectionHeader(
                        title: "Today's Medications",
                        actionLabel: 'Details',
                        onAction: () => context.push(AppRouter.reminders),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: activeReminders.isEmpty
                          ? _buildEmptyRemindersCard(context, isDark)
                          : Column(
                              children: List.generate(
                                activeReminders.length,
                                (index) => _buildMedicineInteractiveCard(
                                  activeReminders[index],
                                  isDark,
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 28),

                    // Daily Insights / Tips
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: SectionHeader(title: 'Daily Insights'),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildHealthTipCard(dailyTip, isDark),
                    ),

                    const SizedBox(height: 120), // Bottom padding for shell FAB overlap
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Layout Helper Widgets
  // ==========================================

  Widget _buildUploadBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analyze Prescription',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Upload or take a photo of your prescription. Our AI reads medications, checks safety, and sets reminders.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push(AppRouter.scan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6C63FF),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.document_scanner_rounded, size: 18),
                  label: const Text(
                    'Scan Now',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_enhance_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, bool isDark) {
    final actions = [
      {
        'label': 'Scan Rx',
        'icon': Icons.document_scanner_outlined,
        'bg': const Color(0xFFEEF0FD),
        'color': const Color(0xFF6C63FF),
        'onTap': () => context.push(AppRouter.scan),
      },
      {
        'label': 'AI Chat',
        'icon': Icons.psychology_outlined,
        'bg': const Color(0xFFF5F3FF),
        'color': const Color(0xFF4F46E5),
        'onTap': () => context.go(AppRouter.aiChat),
      },
      {
        'label': 'Reminders',
        'icon': Icons.notifications_active_outlined,
        'bg': const Color(0xFFFEF3C7),
        'color': const Color(0xFFD97706),
        'onTap': () => context.push(AppRouter.reminders),
      },
      {
        'label': 'Records',
        'icon': Icons.assignment_outlined,
        'bg': const Color(0xFFE0F2FE),
        'color': const Color(0xFF0284C7),
        'onTap': () => context.go(AppRouter.prescriptions),
      },
    ];

    return Row(
      children: List.generate(
        actions.length,
        (index) {
          final act = actions[index];
          return Expanded(
            child: GestureDetector(
              onTap: act['onTap'] as VoidCallback,
              child: Container(
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : 8,
                  right: index == 3 ? 0 : 8,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceCardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.015),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: act['bg'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(act['icon'] as IconData, color: act['color'] as Color, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      act['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    )
        .animate()
        .fadeIn(delay: 150.ms, duration: 450.ms)
        .slideY(begin: 0.1, end: 0, delay: 150.ms);
  }

  // --- Recent Activity Helpers ---

  Widget _buildPrescriptionShimmer() {
    return SkeletonLoader(
      child: Column(
        children: [
          SkeletonBox(width: double.infinity, height: 74, borderRadius: AppSpacing.borderRadiusMd),
          const SizedBox(height: 10),
          SkeletonBox(width: double.infinity, height: 74, borderRadius: AppSpacing.borderRadiusMd),
        ],
      ),
    );
  }

  Widget _buildPrescriptionError(String err) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sync failed: $err',
              style: const TextStyle(fontSize: 12, color: AppColors.danger),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.danger, size: 20),
            onPressed: () => ref.invalidate(prescriptionsProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionEmpty(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        children: [
          const Icon(Icons.description_outlined, color: Colors.grey, size: 36),
          const SizedBox(height: 10),
          const Text(
            'No Scanned Prescriptions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Upload a medical prescription to generate structured records and safety checkouts.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRouter.scan),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Scan First prescription'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionActivityCard(Map<String, dynamic> item, bool isDark) {
    final title = item['title'] as String? ?? 'Prescription Record';
    final doctor = item['doctor_name'] as String? ?? 'Unknown Doctor';
    final hospital = item['hospital_name'] as String? ?? 'Clinic';
    final date = item['prescribed_date'] as String? ?? 'No date';
    final status = item['status'] as String? ?? 'active';
    final medicines = item['medicines'] as List? ?? [];

    final isActive = status == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _showPrescriptionDetails(context, item),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.description_rounded, color: Color(0xFF6C63FF), size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF10B981).withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: isActive ? const Color(0xFF10B981) : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Dr. $doctor · $hospital',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'Date: $date · Contains ${medicines.length} drug(s)',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }

  void _showPrescriptionDetails(BuildContext context, Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = item['title'] as String? ?? 'Prescription Record';
    final doctor = item['doctor_name'] as String? ?? 'Unknown Doctor';
    final hospital = item['hospital_name'] as String? ?? 'Clinic';
    final date = item['prescribed_date'] as String? ?? 'No date';
    final status = item['status'] as String? ?? 'active';
    final medicines = item['medicines'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: AppSpacing.borderRadiusTopXxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'active'
                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: status == 'active' ? const Color(0xFF10B981) : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Prescribed by Dr. $doctor',
                style: AppTypography.titleSmall.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              Text(
                'Hospital: $hospital',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              Text(
                'Date: $date',
                style: AppTypography.bodySmall.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              const Text(
                'Medicines Extracted:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (medicines.isEmpty)
                const Text('No medicines found in this prescription.')
              else
                for (final med in medicines)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceCardDark : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.medication_rounded, color: Color(0xFF6C63FF), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med is Map ? (med['medicine_name'] ?? 'Medicine') : med.toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Dosage: ${med is Map ? (med['dosage'] ?? '—') : '—'} · Freq: ${med is Map ? (med['frequency'] ?? '—') : '—'}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              if (med is Map &&
                                  med['instruction'] != null &&
                                  med['instruction'].toString().isNotEmpty &&
                                  med['instruction'].toString() != '—') ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Instruction: ${med['instruction']}',
                                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go(AppRouter.prescriptions);
                  },
                  icon: const Icon(Icons.list_alt_rounded),
                  label: const Text('View All Health Records'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Compliance Interactive Cards ---

  Widget _buildMedicineInteractiveCard(ReminderModel r, bool isDark) {
    final status = _complianceActions[r.id] ?? 'pending';

    Color stateColor = const Color(0xFF6C63FF);
    IconData stateIcon = Icons.radio_button_off_rounded;
    if (status == 'taken') {
      stateColor = const Color(0xFF10B981);
      stateIcon = Icons.check_circle_rounded;
    } else if (status == 'skipped') {
      stateColor = Colors.amber;
      stateIcon = Icons.skip_next_rounded;
    } else if (status == 'missed') {
      stateColor = Colors.red;
      stateIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status != 'pending'
              ? stateColor.withValues(alpha: 0.4)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: status != 'pending' ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status Action Clicker
          GestureDetector(
            onTap: () => _showCompliancePicker(r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: stateColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(stateIcon, color: stateColor, size: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.medicineName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${r.dosage} · Weekly Adherence',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTimeOfDay(r.time),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: stateColor,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: stateColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCompliancePicker(ReminderModel r) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mark ${r.medicineName}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('Update compliance status for this dosage.'),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.check_circle_rounded, color: const Color(0xFF10B981), size: 28),
                title: const Text('Mark as Taken'),
                onTap: () {
                  setState(() {
                    _complianceActions[r.id] = 'taken';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.skip_next_rounded, color: Colors.amber, size: 28),
                title: const Text('Mark as Skipped'),
                onTap: () {
                  setState(() {
                    _complianceActions[r.id] = 'skipped';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_rounded, color: Colors.red, size: 28),
                title: const Text('Mark as Missed'),
                onTap: () {
                  setState(() {
                    _complianceActions[r.id] = 'missed';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyRemindersCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.alarm_add_rounded, color: Color(0xFF6C63FF), size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No active alarms',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Scan a prescription or add a manual alarm.',
                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(AppRouter.reminders),
            child: const Text(
              'Add',
              style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTipCard(String tip, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 Daily Insight',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  tip,
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.45, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(Icons.health_and_safety_rounded, color: Colors.white.withValues(alpha: 0.2), size: 48),
        ],
      ),
    );
  }

  // --- Notifications Drawers Bottom Sheet ---

  void _showNotificationsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reminders = ref.watch(reminderListProvider);
    final activeReminders = reminders.where((r) => r.isActive).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: AppSpacing.borderRadiusTopXxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Alerts & Notifications',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Dismiss', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildNotificationItem(
                icon: Icons.alarm_rounded,
                iconColor: const Color(0xFFD97706),
                title: activeReminders.isEmpty ? 'No Meds Scheduled' : 'Today\'s Med Schedule',
                description: activeReminders.isEmpty
                    ? 'You have no active medication reminders. Schedule an alarm to get alerts.'
                    : 'You have ${activeReminders.length} active alarms scheduled for today.',
                time: 'Now',
                isDark: isDark,
              ),
              const Divider(),
              _buildNotificationItem(
                icon: Icons.shield_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Drug Safety Scan',
                description: 'We checked your active medicines for potential conflicts. Status: Safe.',
                time: '1h ago',
                isDark: isDark,
              ),
              const Divider(),
              _buildNotificationItem(
                icon: Icons.translate_rounded,
                iconColor: const Color(0xFF6C63FF),
                title: 'Multilingual Explanations',
                description: 'Prescription analysis is fully optimized for English, Hindi, Tamil, and Spanish.',
                time: '1d ago',
                isDark: isDark,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String time,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final min = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }
}

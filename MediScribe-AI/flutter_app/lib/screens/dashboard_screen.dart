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
import '../widgets/section_header.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/glass_card.dart';
import '../main.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final reminders = ref.watch(reminderListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    if (authState is AuthInitial || authState is AuthLoading) {
      return const Scaffold(body: SkeletonDashboard());
    }

    final userName = authState is Authenticated
        ? authState.user.fullName.split(' ').first
        : 'there';
    final todayReminders = reminders.where((r) => r.isActive).toList();
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: RefreshIndicator(
        color: AppColors.primaryTeal,
        onRefresh: () async {
          await ref.read(authProvider.notifier).checkAuthStatus();
        },
        child: CustomScrollView(
          slivers: [
            // ─── Gradient Header SliverAppBar ───────────────────────
            SliverAppBar(
              expandedHeight: 200,
              collapsedHeight: 70,
              pinned: true,
              floating: false,
              backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.dashboardHeaderGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageHorizontal,
                        AppSpacing.lg,
                        AppSpacing.pageHorizontal,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$greeting,',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: Colors.white.withValues(alpha: 0.75),
                                    ),
                                  ).animate().fadeIn(duration: 400.ms),
                                  Text(
                                    userName,
                                    style: AppTypography.headlineLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                                      .animate()
                                      .fadeIn(delay: 100.ms, duration: 400.ms)
                                      .slideX(begin: -0.1, end: 0, delay: 100.ms),
                                ],
                              ),
                              // Avatar + theme toggle
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      final next = themeMode == ThemeMode.dark
                                          ? ThemeMode.light
                                          : ThemeMode.dark;
                                      ref.read(themeModeProvider.notifier).state = next;
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  AppSpacing.hGap12,
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.20),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                        style: AppTypography.titleLarge.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          AppSpacing.vGap16,
                          Text(
                            '${_formattedDate()} · ${todayReminders.length} reminders today',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ─── Body Content ────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppSpacing.xl),

                  // Stat Cards
                  Padding(
                    padding: AppSpacing.pagePadding,
                    child: _buildStatCards(context, isDark, todayReminders.length),
                  ),

                  AppSpacing.vGap28,

                  // Quick Actions
                  Padding(
                    padding: AppSpacing.pagePadding,
                    child: SectionHeader(title: 'Quick Actions'),
                  ),
                  AppSpacing.vGap16,
                  Padding(
                    padding: AppSpacing.pagePadding,
                    child: _buildQuickActions(context, isDark),
                  ),

                  AppSpacing.vGap28,

                  // Today's Reminders
                  Padding(
                    padding: AppSpacing.pagePadding,
                    child: SectionHeader(
                      title: "Today's Reminders",
                      actionLabel: 'See All',
                      onAction: () => context.go(AppRouter.reminders),
                    ),
                  ),
                  AppSpacing.vGap16,
                  todayReminders.isEmpty
                      ? _buildEmptyRemindersCard(context, isDark)
                      : SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: AppSpacing.pagePadding,
                            itemCount: todayReminders.take(5).length,
                            separatorBuilder: (_, __) => AppSpacing.hGap12,
                            itemBuilder: (ctx, i) {
                              final r = todayReminders[i];
                              return _buildReminderMiniCard(r.medicineName, r.dosage,
                                  r.time.format(ctx), isDark, i);
                            },
                          ),
                        ),

                  AppSpacing.vGap28,

                  // Health Tips
                  Padding(
                    padding: AppSpacing.pagePadding,
                    child: SectionHeader(title: 'Health Tip'),
                  ),
                  AppSpacing.vGap16,
                  Padding(
                    padding: AppSpacing.pagePadding,
                    child: _buildHealthTipCard(isDark),
                  ),

                  AppSpacing.vGap28,
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(BuildContext context, bool isDark, int reminderCount) {
    final stats = [
      {
        'label': 'Prescriptions',
        'value': '0',
        'icon': Icons.description_rounded,
        'gradient': AppColors.primaryGradient,
      },
      {
        'label': "Today's Alarms",
        'value': '$reminderCount',
        'icon': Icons.alarm_rounded,
        'gradient': AppColors.purpleGradient,
      },
      {
        'label': 'Adherence',
        'value': '—%',
        'icon': Icons.trending_up_rounded,
        'gradient': AppColors.blueGradient,
      },
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? AppSpacing.md : 0),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: s['gradient'] as LinearGradient,
              borderRadius: AppSpacing.borderRadiusLg,
              boxShadow: [
                BoxShadow(
                  color: ((s['gradient'] as LinearGradient).colors.first).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(s['icon'] as IconData, color: Colors.white.withValues(alpha: 0.85), size: 22),
                AppSpacing.vGap12,
                Text(
                  s['value'] as String,
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                AppSpacing.vGap4,
                Text(
                  s['label'] as String,
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          )
              .animate(delay: (i * 80).ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, end: 0, duration: 400.ms),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    final actions = [
      {'icon': Icons.document_scanner_rounded, 'label': 'Scan Rx', 'route': AppRouter.scan, 'color': AppColors.primaryTeal},
      {'icon': Icons.alarm_add_rounded, 'label': 'Add Alarm', 'route': AppRouter.reminders, 'color': AppColors.statCardPurple},
      {'icon': Icons.description_rounded, 'label': 'Records', 'route': AppRouter.prescriptions, 'color': AppColors.statCardBlue},
      {'icon': Icons.calendar_month_rounded, 'label': 'Schedule', 'route': AppRouter.schedule, 'color': AppColors.statCardOrange},
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 0,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 0.85,
      children: actions.asMap().entries.map((entry) {
        final i = entry.key;
        final a = entry.value;
        return GestureDetector(
          onTap: () => context.push(a['route'] as String),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (a['color'] as Color).withValues(alpha: isDark ? 0.15 : 0.10),
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: Border.all(
                    color: (a['color'] as Color).withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 26),
              ),
              AppSpacing.vGap8,
              Text(
                a['label'] as String,
                style: AppTypography.labelMedium.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          )
              .animate(delay: (i * 60).ms)
              .fadeIn(duration: 350.ms)
              .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), duration: 350.ms),
        );
      }).toList(),
    );
  }

  Widget _buildReminderMiniCard(
      String name, String dose, String time, bool isDark, int index) {
    return GlassCard(
      width: 140,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.15),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: const Icon(Icons.medication_rounded, color: AppColors.primaryTeal, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(dose,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondaryLight, fontSize: 11)),
              Text(time,
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.primaryTeal, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    )
        .animate(delay: (index * 70).ms)
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.2, end: 0, duration: 350.ms);
  }

  Widget _buildEmptyRemindersCard(BuildContext context, bool isDark) {
    return Padding(
      padding: AppSpacing.pagePadding,
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: const Icon(Icons.alarm_add_rounded, color: AppColors.primaryTeal, size: 28),
            ),
            AppSpacing.hGap16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No reminders yet',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                  AppSpacing.vGap4,
                  Text('Tap to add your first alarm',
                      style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRouter.reminders),
              child: const Text('Add'),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 400.ms),
    );
  }

  Widget _buildHealthTipCard(bool isDark) {
    return GradientCard(
      gradient: AppColors.accentGradient,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Daily Tip',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.80),
                  ),
                ),
                AppSpacing.vGap8,
                Text(
                  'Take medications at the same time daily for best results.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.hGap16,
          Icon(Icons.health_and_safety_rounded, color: Colors.white.withValues(alpha: 0.6), size: 48),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0, delay: 500.ms);
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/typography.dart';
import '../core/theme/app_theme.dart';
import '../services/auth_provider.dart';
import '../core/routes/app_router.dart';
import '../widgets/app_button.dart';
import '../main.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _bloodGroupOptions = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  String? _selectedBloodGroup;


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.user;
    final initial = user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Profile Hero Header ──────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            collapsedHeight: 70,
            pinned: true,
            floating: false,
            backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            leading: null,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.dashboardHeaderGradient,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppSpacing.vGap16,
                      // Avatar
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: AppTypography.displayMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.7, 0.7),
                            end: const Offset(1, 1),
                            duration: 500.ms,
                            curve: Curves.elasticOut,
                          ),

                      AppSpacing.vGap12,
                      Text(
                        user.fullName,
                        style: AppTypography.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      AppSpacing.vGap4,
                      Text(
                        user.phone ?? '—',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.70),
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                      AppSpacing.vGap8,
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: AppSpacing.borderRadiusRound,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ).animate().fadeIn(delay: 350.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal, AppSpacing.xl, AppSpacing.pageHorizontal, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Account Info Card
                _sectionCard(
                  title: 'Account Details',
                  icon: Icons.person_rounded,
                  isDark: isDark,
                  children: [
                    _infoRow(Icons.badge_rounded, 'Full Name', user.fullName, isDark),
                    _divider(isDark),
                    _infoRow(Icons.phone_rounded, 'Phone', user.phone ?? '—', isDark),
                    _divider(isDark),
                    _infoRow(Icons.medical_services_rounded, 'Role',
                        user.role.isNotEmpty ? (user.role[0].toUpperCase() + user.role.substring(1)) : '—', isDark),
                  ],
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0, delay: 100.ms),

                AppSpacing.vGap20,

                // Health Info Card
                _sectionCard(
                  title: 'Health Profile',
                  icon: Icons.favorite_rounded,
                  isDark: isDark,
                  children: [
                    _infoRow(Icons.bloodtype_rounded, 'Blood Group',
                        _selectedBloodGroup ?? 'Not set', isDark,
                        trailing: DropdownButton<String>(
                          value: _selectedBloodGroup,
                          underline: const SizedBox.shrink(),
                          hint: Text('Select',
                              style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.primaryTeal)),
                          items: _bloodGroupOptions
                              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedBloodGroup = v),
                        )),
                    _divider(isDark),
                    _infoRow(Icons.language_rounded, 'Language', 'English (en)', isDark),
                  ],
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0, delay: 200.ms),

                AppSpacing.vGap20,

                // Preferences Card
                _sectionCard(
                  title: 'Preferences',
                  icon: Icons.tune_rounded,
                  isDark: isDark,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        child: Icon(
                          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: AppColors.primaryTeal,
                          size: 20,
                        ),
                      ),
                      title: Text('Dark Mode',
                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Text('Toggle app theme',
                          style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                      trailing: Switch.adaptive(
                        value: themeMode == ThemeMode.dark,
                        activeThumbColor: AppColors.primaryTeal,
                        onChanged: (val) {
                          ref.read(themeModeProvider.notifier).state =
                              val ? ThemeMode.dark : ThemeMode.light;
                        },
                      ),
                    ),
                    _divider(isDark),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.statCardBlue.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        child: const Icon(Icons.notifications_rounded,
                            color: AppColors.statCardBlue, size: 20),
                      ),
                      title: Text('Notifications',
                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Text('Manage alarm preferences',
                          style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(AppRouter.reminders),
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0, delay: 300.ms),

                AppSpacing.vGap20,

                // About Card
                _sectionCard(
                  title: 'About',
                  icon: Icons.info_outline_rounded,
                  isDark: isDark,
                  children: [
                    _infoRow(Icons.app_registration_rounded, 'App Version', '1.0.0', isDark),
                    _divider(isDark),
                    _infoRow(Icons.security_rounded, 'Privacy Policy', 'View', isDark,
                        isLink: true),
                  ],
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0, delay: 400.ms),

                AppSpacing.vGap28,

                // Logout Button
                AppButton.danger(
                  label: 'Sign Out',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Sign Out',
                                  style: TextStyle(color: AppColors.danger))),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go(AppRouter.login);
                    }
                  },
                  prefixIcon: Icons.logout_rounded,
                )
                    .animate()
                    .fadeIn(delay: 500.ms)
                    .slideY(begin: 0.1, end: 0, delay: 500.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCardDark : Colors.white,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: isDark ? AppTheme.premiumShadowDark : AppTheme.premiumShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Icon(icon, color: AppColors.primaryTeal, size: 18),
                ),
                AppSpacing.hGap12,
                Text(title,
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, bool isDark,
      {Widget? trailing, bool isLink = false}) {
    return Row(
      children: [
        Icon(icon,
            size: 18,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        AppSpacing.hGap12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTypography.labelMedium.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              Text(value,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isLink
                        ? (isDark ? AppColors.primaryTealLight : AppColors.primaryTeal)
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  )),
            ],
          ),
        ),
        if (trailing != null) trailing,
        if (isLink) Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.primaryTeal),
      ],
    );
  }

  Widget _divider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Divider(
        height: 1,
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
      ),
    );
  }
}

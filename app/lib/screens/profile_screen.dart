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
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    // Safety guard: if auth state is not Authenticated (e.g. mid-logout transition
    // before GoRouter's deferred redirect fires), show a themed loader.
    // This will only flash for at most 1 frame before GoRouter navigates to /login.
    if (authState is! Authenticated || _isLoggingOut) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: const Color(0xFF6C63FF),
                strokeWidth: 2.5,
              ),
              const SizedBox(height: 16),
              Text(
                'Signing out...',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
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
                                  color: const Color(0xFF6C63FF))),
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
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        child: Icon(
                          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: const Color(0xFF6C63FF),
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
                        activeThumbColor: const Color(0xFF6C63FF),
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

                                // Health Info Card
                _sectionCard(
                  title: 'SOS Emergency Support',
                  icon: Icons.sos_rounded,
                  isDark: isDark,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Emergency Assistance',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Need immediate help? Press the button below to simulate dialing emergency medical assistance and sharing your active health details.',
                            style: TextStyle(fontSize: 12, height: 1.45, color: Color(0xFFE11D48)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Row(
                                    children: [
                                      Icon(Icons.call_rounded, color: Colors.red),
                                      SizedBox(width: 10),
                                      Text('SOS Triggered'),
                                    ],
                                  ),
                                  content: const Text(
                                    'Simulating emergency call (dialing 112 / ambulance)... \n\nSharing your MediScribe AI prescription records and GPS coordinates with emergency dispatch.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancel Emergency Call', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.red.withValues(alpha: 0.4),
                              elevation: 4,
                              minimumSize: const Size(double.infinity, 46),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.sos_rounded, size: 20),
                            label: const Text('TRIGGER EMERGENCY SOS', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                AppSpacing.vGap20,

                // Logout Button
                AppButton.danger(
                  label: 'Sign Out',
                  isLoading: _isLoggingOut,
                  onPressed: _isLoggingOut
                      ? null
                      : () async {
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

                          if (confirm == true && mounted) {
                            setState(() => _isLoggingOut = true);

                            // DO NOT call context.go() here.
                            // If we navigate to /login while authProvider is still
                            // Authenticated, GoRouter's redirect immediately bounces
                            // us back to /dashboard (redirect: Authenticated → /dashboard).
                            //
                            // The correct pattern: await logout() to clear tokens and
                            // set state = Unauthenticated, then let GoRouter's deferred
                            // redirect (addPostFrameCallback) handle navigation to /login.
                            await ref.read(authProvider.notifier).logout();

                            // At this point authProvider is Unauthenticated.
                            // GoRouter's addPostFrameCallback will fire on the next frame
                            // and redirect to /login. We only reset _isLoggingOut if
                            // the widget is somehow still mounted (unlikely, but safe).
                            if (mounted) setState(() => _isLoggingOut = false);
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
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Icon(icon, color: const Color(0xFF6C63FF), size: 18),
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
                        ? (isDark ? const Color(0xFF8C85FF) : const Color(0xFF6C63FF))
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  )),
            ],
          ),
        ),
        if (trailing != null) trailing,
        if (isLink) const Icon(Icons.open_in_new_rounded, size: 16, color: const Color(0xFF6C63FF)),
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

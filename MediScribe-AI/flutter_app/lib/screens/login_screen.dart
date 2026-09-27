import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/typography.dart';
import '../core/routes/app_router.dart';
import '../services/auth_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/premium_input.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
          _phoneController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show error snackbar
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D1B2E), AppColors.backgroundDark],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE0F7F4), AppColors.backgroundLight],
                ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Header
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: AppSpacing.borderRadiusMd,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryTeal.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.medication_liquid_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.2, end: 0, duration: 400.ms),

                const SizedBox(height: 32),

                Text(
                  'Welcome back',
                  style: AppTypography.displayLarge.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w800,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0, delay: 100.ms),

                const SizedBox(height: 8),

                Text(
                  'Sign in to manage your prescriptions and health records.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 40),

                // Form card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceCardDark : Colors.white,
                    borderRadius: AppSpacing.borderRadiusXl,
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                    boxShadow: isDark
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 32,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                              blurRadius: 28,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        PremiumTextField(
                          label: 'Phone Number',
                          hint: '+91 98765 43210',
                          controller: _phoneController,
                          prefixIcon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            return null;
                          },
                        ),
                        AppSpacing.vGap16,
                        PremiumTextField(
                          label: 'Password',
                          hint: 'Enter your password',
                          controller: _passwordController,
                          prefixIcon: Icons.lock_rounded,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _login(),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        AppSpacing.vGap8,
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        AppSpacing.vGap8,
                        AppButton.primary(
                          label: 'Sign In',
                          onPressed: isLoading ? null : _login,
                          isLoading: isLoading,
                          prefixIcon: Icons.login_rounded,
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 500.ms)
                    .slideY(begin: 0.2, end: 0, delay: 300.ms),

                const SizedBox(height: 28),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Text(
                        'New to MediScribe?',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                  ],
                ),

                const SizedBox(height: 20),

                AppButton.outline(
                  label: 'Create Account',
                  onPressed: () => context.push(AppRouter.register),
                  prefixIcon: Icons.person_add_rounded,
                ),

                const SizedBox(height: 32),

                // Trust indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _trustBadge(Icons.lock_rounded, 'Secure', isDark),
                    AppSpacing.hGap24,
                    _trustBadge(Icons.verified_rounded, 'HIPAA Safe', isDark),
                    AppSpacing.hGap24,
                    _trustBadge(Icons.health_and_safety_rounded, 'Private', isDark),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _trustBadge(IconData icon, String label, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 20, color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

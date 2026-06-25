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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  int _currentStep = 0;
  String _selectedRole = 'patient';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    await ref.read(authProvider.notifier).register(
          _nameController.text.trim(),
          _phoneController.text.trim(),
          _passwordController.text,
          _selectedRole,
        );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
        return;
      }
    }
    setState(() => _currentStep = 1);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: AppColors.danger),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _currentStep == 1
              ? () => setState(() => _currentStep = 0)
              : () => context.pop(),
        ),
        title: const Text('Create Account'),
      ),
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Progress indicator
                  _buildProgressIndicator(isDark),

                  const SizedBox(height: 32),

                  // Step header
                  Text(
                    _currentStep == 0 ? 'Your Details' : 'Set Password',
                    style: AppTypography.displayMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ).animate(key: ValueKey(_currentStep)).fadeIn().slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 8),

                  Text(
                    _currentStep == 0
                        ? 'Tell us who you are to personalise your experience.'
                        : 'Secure your account with a strong password.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ).animate(key: ValueKey('sub$_currentStep')).fadeIn(delay: 100.ms),

                  const SizedBox(height: 32),

                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceCardDark : Colors.white,
                      borderRadius: AppSpacing.borderRadiusXl,
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                          blurRadius: 28,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: 300.ms,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _currentStep == 0
                          ? _buildStep1(isDark)
                          : _buildStep2(isDark, isLoading),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15, end: 0, delay: 200.ms),

                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRouter.login),
                        child: Text(
                          'Sign In',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    return Row(
      children: List.generate(2, (i) {
        final isActive = i <= _currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 1 ? 8 : 0),
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark ? AppColors.primaryTealLight : AppColors.primaryTeal)
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              borderRadius: AppSpacing.borderRadiusRound,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStep1(bool isDark) {
    return Column(
      key: const ValueKey('step1'),
      children: [
        PremiumTextField(
          label: 'Full Name',
          hint: 'Dr. / Mr. / Ms. ...',
          controller: _nameController,
          prefixIcon: Icons.person_rounded,
          textInputAction: TextInputAction.next,
          validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
        ),
        AppSpacing.vGap16,
        PremiumTextField(
          label: 'Phone Number',
          hint: '+91 98765 43210',
          controller: _phoneController,
          prefixIcon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          validator: (v) => v == null || v.trim().isEmpty ? 'Phone is required' : null,
        ),
        AppSpacing.vGap20,
        // Role selector
        Text('I am a:', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
        AppSpacing.vGap12,
        Row(
          children: [
            _roleChip('patient', Icons.person_rounded, 'Patient', isDark),
            AppSpacing.hGap12,
            _roleChip('caregiver', Icons.favorite_rounded, 'Caregiver', isDark),
          ],
        ),
        AppSpacing.vGap20,
        AppButton.primary(
          label: 'Continue',
          onPressed: _nextStep,
          suffixIcon: Icons.arrow_forward_rounded,
        ),
      ],
    );
  }

  Widget _buildStep2(bool isDark, bool isLoading) {
    return Column(
      key: const ValueKey('step2'),
      children: [
        PremiumTextField(
          label: 'Password',
          hint: 'At least 8 characters',
          controller: _passwordController,
          prefixIcon: Icons.lock_rounded,
          obscureText: true,
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 8) return 'Minimum 8 characters';
            return null;
          },
        ),
        AppSpacing.vGap16,
        PremiumTextField(
          label: 'Confirm Password',
          hint: 'Re-enter password',
          controller: _confirmController,
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _register(),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please confirm your password';
            if (v != _passwordController.text) return 'Passwords do not match';
            return null;
          },
        ),
        AppSpacing.vGap20,
        AppButton.primary(
          label: 'Create Account',
          onPressed: isLoading ? null : _register,
          isLoading: isLoading,
          prefixIcon: Icons.check_circle_rounded,
        ),
      ],
    );
  }

  Widget _roleChip(String role, IconData icon, String label, bool isDark) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.navIndicatorDark : AppColors.navIndicatorLight)
                : (isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC)),
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(
              color: isSelected
                  ? (isDark ? AppColors.primaryTealLight : AppColors.primaryTeal)
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? (isDark ? AppColors.primaryTealLight : AppColors.primaryTeal)
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              AppSpacing.vGap8,
              Text(
                label,
                style: AppTypography.titleSmall.copyWith(
                  color: isSelected
                      ? (isDark ? AppColors.primaryTealLight : AppColors.primaryTeal)
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

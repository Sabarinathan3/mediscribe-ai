import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';

/// Main navigation shell with Material 3 NavigationBar and center FAB for scanning.
class MainNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationShell({
    super.key,
    required this.navigationShell,
  });

  void _onTabTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      extendBody: true,
      floatingActionButton: _buildCenterFab(context, isDark),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(context, isDark, currentIndex),
    );
  }

  Widget _buildCenterFab(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/scan'),
      child: Container(
        width: AppSpacing.fabSize + 8,
        height: AppSpacing.fabSize + 8,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
          ],
        ),
        child: const Icon(
          Icons.document_scanner_rounded,
          color: Colors.white,
          size: 28,
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(
            duration: 3000.ms,
            color: Colors.white.withValues(alpha: 0.25),
            delay: 2000.ms,
          ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.navBarDark : AppColors.navBarLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSpacing.bottomNavHeight,
          child: Row(
            children: [
              // Left: Dashboard
              Expanded(child: _navItem(context, 0, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Home', currentIndex, isDark)),
              // Left-center: AI Chat
              Expanded(child: _navItem(context, 1, Icons.psychology_rounded, Icons.psychology_outlined, 'AI Chat', currentIndex, isDark)),
              // Center gap for FAB
              const SizedBox(width: AppSpacing.fabSize + 24),
              // Right-center: Prescriptions
              Expanded(child: _navItem(context, 2, Icons.description_rounded, Icons.description_outlined, 'Records', currentIndex, isDark)),
              // Right: Profile
              Expanded(child: _navItem(context, 3, Icons.person_rounded, Icons.person_outlined, 'Profile', currentIndex, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    int currentIndex,
    bool isDark,
  ) {
    final isSelected = currentIndex == index;
    final color = isSelected
        ? (isDark ? const Color(0xFF8C85FF) : const Color(0xFF6C63FF))
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: 200.ms,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? AppColors.navIndicatorDark : AppColors.navIndicatorLight)
                  : Colors.transparent,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: color,
              size: 22,
            ),
          ),
          AppSpacing.vGap4,
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

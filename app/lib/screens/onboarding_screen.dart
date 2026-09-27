import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../core/routes/app_router.dart';
import '../core/theme/typography.dart';
import '../models/onboarding_model.dart';
import '../services/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage(int totalSlides) {
    if (_currentPage < totalSlides - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    await ref.read(onboardingControllerProvider).completeOnboarding();
    if (mounted) {
      context.go(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slidesState = ref.watch(onboardingSlidesProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F3FF), // Very soft lavender
              Color(0xFFFFFFFF), // White
            ],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 1. Decorative Grid & Cross Background Pattern
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: BackgroundPatternPainter(),
                  ),
                ),
              ),

              // 2. Main Content Layout
              Column(
                children: [
                  // Top Navigation Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 48), // Spacer for centering
                        const OnboardingLogo(),
                        TextButton(
                          onPressed: _finishOnboarding,
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Title Text Section (Fixed above the swipable PageView for visual stability)
                  const SizedBox(height: 12),
                  const _TitleAndBrand(),

                  // PageView Slides Area
                  Expanded(
                    child: slidesState.when(
                      data: (slides) {
                        if (slides.isEmpty) {
                          return const Center(child: Text("No slides available."));
                        }
                        return PageView.builder(
                          controller: _pageController,
                          onPageChanged: _onPageChanged,
                          itemCount: slides.length,
                          itemBuilder: (context, index) {
                            return _SlideContent(slide: slides[index]);
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      error: (err, stack) {
                        // Safe state print, should not happen since fallback slides are provided
                        return const Center(child: Text("An error occurred."));
                      },
                    ),
                  ),

                  // Bottom Action Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: slidesState.when(
                      data: (slides) {
                        final isLastPage = _currentPage == slides.length - 1;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Page Dash Indicators
                            _PageIndicators(
                              total: slides.length,
                              current: _currentPage,
                            ),
                            const SizedBox(height: 32),

                            // Next / Get Started CTA Button
                            ElevatedButton(
                              onPressed: () => _nextPage(slides.length),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                shadowColor: const Color(0xFF6366F1).withOpacity(0.35),
                                elevation: 6,
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                isLastPage ? 'Get Started' : 'Next',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            )
                                .animate(target: isLastPage ? 1 : 0)
                                .scale(
                                  duration: 200.ms,
                                  begin: const Offset(1, 1),
                                  end: const Offset(1.02, 1.02),
                                )
                                .shimmer(
                                  delay: 500.ms,
                                  duration: 1000.ms,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                          ],
                        );
                      },
                      loading: () => const SizedBox(height: 110),
                      error: (_, __) => const SizedBox(height: 110),
                    ),
                  ),

                  // Footer Security Branding
                  const SizedBox(height: 16),
                  const _FooterSecurityBranding(),
                  const SizedBox(height: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 1. Background Pattern Painter
// ==========================================
class BackgroundPatternPainter extends CustomPainter {
  const BackgroundPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.04)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Draw grid of dots in top-right
    final double startX = size.width - 90;
    const double startY = 40;
    const double spacing = 12;
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 6; j++) {
        canvas.drawCircle(
          Offset(startX + (i * spacing), startY + (j * spacing)),
          1.5,
          paint,
        );
      }
    }

    // Draw decorative crosses in top-left
    _drawCross(canvas, const Offset(36, 60), 14, paint);
    _drawCross(canvas, const Offset(55, 110), 10, paint);
  }

  void _drawCross(Canvas canvas, Offset center, double size, Paint paint) {
    canvas.drawLine(
      Offset(center.dx - size / 2, center.dy),
      Offset(center.dx + size / 2, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - size / 2),
      Offset(center.dx, center.dy + size / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// 2. Logo Widget (Stack paper & heart)
// ==========================================
class OnboardingLogo extends StatelessWidget {
  const OnboardingLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rx Paper
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6366F1),
                width: 3.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Rₓ',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 24,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 34,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          // Heart badge overlay
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.favorite_rounded,
                color: Color(0xFF6366F1),
                size: 15,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .scale(
          duration: 600.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 400.ms);
  }
}

// ==========================================
// 3. Title & Brand Header
// ==========================================
class _TitleAndBrand extends StatelessWidget {
  const _TitleAndBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // MediScribeAI Text with Gradient "AI"
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'MediScribe',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                letterSpacing: -0.5,
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
              ).createShader(bounds),
              child: const Text(
                'AI',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'AI-Powered Prescription Interpreter',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4F46E5),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Your Health, Simplified.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 150.ms, duration: 400.ms)
        .slideY(begin: 0.15, end: 0, delay: 150.ms, duration: 400.ms);
  }
}

// ==========================================
// 4. Slide Content (Swipable Area)
// ==========================================
class _SlideContent extends StatelessWidget {
  final OnboardingSlide slide;

  const _SlideContent({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          
          // Image / Illustration Container
          Container(
            height: 230,
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.04),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Image.asset(
              slide.illustrationUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Safe fallback illustration if assets are missing
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2F6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                        color: Color(0xFF94A3B8),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Illustration Asset Loading",
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
              .animate(key: ValueKey(slide.stepNumber))
              .scale(
                duration: 500.ms,
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 400.ms),

          const Spacer(flex: 3),

          // Slide Title & Subtitle (Shown inside the PageView for slides 2-4)
          if (slide.stepNumber > 1) ...[
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.1, end: 0, duration: 300.ms),
            const SizedBox(height: 8),
            Text(
              slide.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.45,
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 24),
          ],

          // Horizontal cards for features
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              slide.features.length,
              (index) => Expanded(
                child: _FeatureCard(
                  feature: slide.features[index],
                  index: index,
                ),
              ),
            ),
          ),
          
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

// ==========================================
// 5. Feature Card Widget
// ==========================================
class _FeatureCard extends StatelessWidget {
  final OnboardingFeature feature;
  final int index;

  const _FeatureCard({
    required this.feature,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: index == 0 ? 0 : 6,
        right: index == 2 ? 0 : 6,
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFF), // Soft purple highlight surface
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEEF0FD),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF0FD),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconData(feature.icon),
              color: const Color(0xFF6366F1),
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          // Label Text
          Text(
            feature.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
              height: 1.25,
            ),
          ),
        ],
      ),
    )
        .animate()
        .scale(
          duration: 350.ms,
          delay: (index * 100).ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(
          duration: 300.ms,
          delay: (index * 100).ms,
        );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'document_scanner':
        return Icons.document_scanner_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'verified_user':
        return Icons.verified_user_rounded;
      case 'camera_alt':
        return Icons.camera_alt_rounded;
      case 'analytics':
        return Icons.analytics_rounded;
      case 'edit_note':
        return Icons.edit_note_rounded;
      case 'check_circle':
        return Icons.check_circle_rounded;
      case 'group':
        return Icons.group_rounded;
      case 'notifications_active':
        return Icons.notifications_active_rounded;
      case 'warning':
        return Icons.warning_rounded;
      case 'rule':
        return Icons.rule_rounded;
      case 'health_and_safety':
        return Icons.health_and_safety_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

// ==========================================
// 6. Custom Dash Indicators
// ==========================================
class _PageIndicators extends StatelessWidget {
  final int total;
  final int current;

  const _PageIndicators({
    required this.total,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        total,
        (index) {
          final isSelected = index == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            width: isSelected ? 30 : 12,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF6366F1).withOpacity(0.18),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 7. Bottom Branding Footer
// ==========================================
class _FooterSecurityBranding extends StatelessWidget {
  const _FooterSecurityBranding();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.shield_outlined,
          size: 16,
          color: Color(0xFF9CA3AF),
        ),
        SizedBox(width: 6),
        Text(
          'Secured. Private. Trusted.',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/onboarding_model.dart';

final onboardingCompletedProvider = StateProvider<bool>((ref) => false);

final onboardingSlidesProvider = FutureProvider<List<OnboardingSlide>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final data = await api.getOnboardingSlides();
    return data.map((json) => OnboardingSlide.fromJson(json)).toList();
  } catch (e) {
    return const [
      OnboardingSlide(
        stepNumber: 1,
        title: "Scan Handwritten Prescriptions",
        subtitle: "Scan handwritten prescriptions instantly with high-accuracy AI OCR transcription.",
        illustrationUrl: "assets/images/onboarding_1.png",
        features: [
          OnboardingFeature(title: "Handwriting OCR", icon: "document_scanner"),
          OnboardingFeature(title: "Scan Instantly", icon: "camera_alt"),
          OnboardingFeature(title: "Digital Records", icon: "verified_user"),
        ],
      ),
      OnboardingSlide(
        stepNumber: 2,
        title: "Understand Your Medicines",
        subtitle: "Understand medicines, exact dosage schedules, guidelines, and side effects in simple language.",
        illustrationUrl: "assets/images/onboarding_1.png",
        features: [
          OnboardingFeature(title: "Dosage Info", icon: "analytics"),
          OnboardingFeature(title: "Side Effects", icon: "rule"),
          OnboardingFeature(title: "Dose Alarms", icon: "notifications_active"),
        ],
      ),
      OnboardingSlide(
        stepNumber: 3,
        title: "Ask AI Assistant Anything",
        subtitle: "Ask the AI assistant anything about your medicines, wellness guidelines, or safety precautions.",
        illustrationUrl: "assets/images/onboarding_1.png",
        features: [
          OnboardingFeature(title: "Ask AI Anything", icon: "psychology"),
          OnboardingFeature(title: "Drug Interactions", icon: "warning"),
          OnboardingFeature(title: "24/7 Guidance", icon: "health_and_safety"),
        ],
      ),
    ];
  }
});

final onboardingControllerProvider = Provider((ref) {
  return OnboardingController(ref);
});

class OnboardingController {
  final Ref _ref;
  OnboardingController(this._ref);

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    _ref.read(onboardingCompletedProvider.notifier).state = true;
  }
}

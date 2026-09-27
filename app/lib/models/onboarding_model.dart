class OnboardingFeature {
  final String title;
  final String icon;

  const OnboardingFeature({
    required this.title,
    required this.icon,
  });

  factory OnboardingFeature.fromJson(Map<String, dynamic> json) {
    return OnboardingFeature(
      title: json['title'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'icon': icon,
    };
  }
}

class OnboardingSlide {
  final int stepNumber;
  final String title;
  final String subtitle;
  final String illustrationUrl;
  final List<OnboardingFeature> features;

  const OnboardingSlide({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.illustrationUrl,
    required this.features,
  });

  factory OnboardingSlide.fromJson(Map<String, dynamic> json) {
    var featuresList = json['features'] as List? ?? [];
    return OnboardingSlide(
      stepNumber: json['step_number'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      illustrationUrl: json['illustration_url'] as String? ?? '',
      features: featuresList
          .map((f) => OnboardingFeature.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step_number': stepNumber,
      'title': title,
      'subtitle': subtitle,
      'illustration_url': illustrationUrl,
      'features': features.map((f) => f.toJson()).toList(),
    };
  }
}

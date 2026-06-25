import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Language {
  final String code;
  final String name;
  final String locale;

  const Language({
    required this.code,
    required this.name,
    required this.locale,
  });
}

class LanguageNotifier extends StateNotifier<Language> {
  static const String _prefsKey = 'mediscribe_language';
  
  static const List<Language> supportedLanguages = [
    Language(code: 'en', name: 'English', locale: 'en-US'),
    Language(code: 'ta', name: 'Tamil (தமிழ்)', locale: 'ta-IN'),
    Language(code: 'hi', name: 'Hindi (हिन्दी)', locale: 'hi-IN'),
    Language(code: 'te', name: 'Telugu (తెలుగు)', locale: 'te-IN'),
    Language(code: 'ml', name: 'Malayalam (മലയാളം)', locale: 'ml-IN'),
  ];

  LanguageNotifier() : super(supportedLanguages[0]) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? langCode = prefs.getString(_prefsKey);
      if (langCode != null) {
        final lang = supportedLanguages.firstWhere(
          (l) => l.code == langCode,
          orElse: () => supportedLanguages[0],
        );
        state = lang;
      }
    } catch (e) {
      // Silently handle
    }
  }

  Future<void> setLanguage(String code) async {
    final lang = supportedLanguages.firstWhere(
      (l) => l.code == code,
      orElse: () => supportedLanguages[0],
    );
    state = lang;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, code);
    } catch (e) {
      // Silently handle
    }
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, Language>((ref) {
  return LanguageNotifier();
});

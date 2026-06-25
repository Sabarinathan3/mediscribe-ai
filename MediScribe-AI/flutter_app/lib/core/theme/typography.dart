import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Outfit'; // Premium healthcare brand typography

  // ==========================================
  // Display Typographies (Hero text)
  // ==========================================
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.2,
  );

  // ==========================================
  // Headlines (Major section titles)
  // ==========================================
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.1,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // ==========================================
  // Titles (Card headers, list headers)
  // ==========================================
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  // ==========================================
  // Body (Paragraphs, read-outs)
  // ==========================================
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ==========================================
  // Labels & Captions (Footnotes, indicators)
  // ==========================================
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.5,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.5,
  );

  // ==========================================
  // TextTheme generators for Theme integration
  // ==========================================
  static TextTheme createTextTheme(Color defaultColor) {
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: defaultColor),
      displayMedium: displayMedium.copyWith(color: defaultColor),
      headlineLarge: headlineLarge.copyWith(color: defaultColor),
      headlineMedium: headlineMedium.copyWith(color: defaultColor),
      titleLarge: titleLarge.copyWith(color: defaultColor),
      titleMedium: titleMedium.copyWith(color: defaultColor),
      titleSmall: titleSmall.copyWith(color: defaultColor),
      bodyLarge: bodyLarge.copyWith(color: defaultColor),
      bodyMedium: bodyMedium.copyWith(color: defaultColor),
      bodySmall: bodySmall.copyWith(color: defaultColor),
      labelLarge: labelLarge.copyWith(color: defaultColor),
      labelMedium: labelMedium.copyWith(color: defaultColor),
    );
  }
}

import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // ==========================================
  // Premium Primary & Secondary Palette
  // ==========================================
  static const Color primaryTeal = Color(0xFF0F766E);     // Deep Emerald Teal
  static const Color primaryTealLight = Color(0xFF14B8A6);// Vibrant Emerald Teal
  static const Color primaryTealDark = Color(0xFF0F766E);

  static const Color secondaryMint = Color(0xFF06B6D4);   // Light Mint Cyan
  static const Color accentCyan = Color(0xFFE0F2FE);      // Soft Cyan Background

  // ==========================================
  // Neutrals (Light Mode)
  // ==========================================
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceCardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textPlaceholderLight = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);

  // ==========================================
  // Neutrals (Dark Mode)
  // ==========================================
  static const Color backgroundDark = Color(0xFF090D16);
  static const Color surfaceDark = Color(0xFF111827);
  static const Color surfaceCardDark = Color(0xFF1F2937);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textPlaceholderDark = Color(0xFF475569);
  static const Color borderDark = Color(0xFF374151);

  // ==========================================
  // Healthcare System Colors
  // ==========================================
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color infoLight = Color(0xFFDBEAFE);

  static const Color successDark = Color(0xFF064E3B);
  static const Color warningDark = Color(0xFF78350F);
  static const Color dangerDark = Color(0xFF7F1D1D);
  static const Color infoDark = Color(0xFF1E3A5F);

  // ==========================================
  // Glassmorphism Tokens
  // ==========================================
  static const Color glassWhite = Color(0xCCFFFFFF);       // White 80%
  static const Color glassDarkSurface = Color(0xCC1F2937); // Dark card 80%
  static const Color glassBorderLight = Color(0x40FFFFFF); // White border 25%
  static const Color glassBorderDark = Color(0x1AFFFFFF);  // Dark border 10%
  static const Color glassOverlayLight = Color(0x0D000000);
  static const Color glassOverlayDark = Color(0x33000000);

  // ==========================================
  // Shimmer Skeleton Colors
  // ==========================================
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);
  static const Color shimmerBaseDark = Color(0xFF1F2937);
  static const Color shimmerHighlightDark = Color(0xFF374151);

  // ==========================================
  // Navigation Bar
  // ==========================================
  static const Color navBarLight = Color(0xFFFAFAFA);
  static const Color navBarDark = Color(0xFF111827);
  static const Color navIndicatorLight = Color(0xFFCCFBF1);
  static const Color navIndicatorDark = Color(0xFF0F4C44);

  // ==========================================
  // Stat Card Gradients
  // ==========================================
  static const Color statCardBlue = Color(0xFF3B82F6);
  static const Color statCardPurple = Color(0xFF8B5CF6);
  static const Color statCardGreen = Color(0xFF10B981);
  static const Color statCardOrange = Color(0xFFF59E0B);

  // ==========================================
  // Apple-Level Soft Gradients
  // ==========================================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06B6D4), Color(0xFF0D9488)],
  );

  static const LinearGradient alertGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFCA5A5), Color(0xFFEF4444)],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F2937), Color(0xFF111827)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D9488), Color(0xFF065F46)],
  );

  static const LinearGradient dashboardHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F766E), Color(0xFF0E7490)],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
  );

  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );
}

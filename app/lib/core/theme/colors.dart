import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // ==========================================
  // Premium Primary & Secondary Palette (Purple & Indigo)
  // ==========================================
  static const Color primaryPurple = Color(0xFF6C63FF);      // Vibrant Healthcare Purple
  static const Color primaryPurpleLight = Color(0xFF8C85FF); // Light Purple Accent
  static const Color primaryPurpleDark = Color(0xFF4B42E5);  // Deep Rich Purple

  static const Color secondaryIndigo = Color(0xFF4F46E5);    // Strong Secondary Indigo
  static const Color accentLightBlue = Color(0xFFE0F2FE);     // Soft Cyan/Blue Background
  static const Color accentLightBlueDark = Color(0xFF0369A1); // Deep Accent Blue

  // ==========================================
  // Neutrals (Light Mode)
  // ==========================================
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceCardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF111827);    // Dark slate gray
  static const Color textSecondaryLight = Color(0xFF4B5563);  // Medium gray
  static const Color textPlaceholderLight = Color(0xFF9CA3AF);
  static const Color borderLight = Color(0xFFE5E7EB);

  // ==========================================
  // Neutrals (Dark Mode)
  // ==========================================
  static const Color backgroundDark = Color(0xFF0B0A0F);     // Super dark purple-black
  static const Color surfaceDark = Color(0xFF12111A);        // Dark slate purple surface
  static const Color surfaceCardDark = Color(0xFF1A1926);    // Dark card surface
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textPlaceholderDark = Color(0xFF4B5563);
  static const Color borderDark = Color(0xFF2E2C3D);

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
  static const Color glassDarkSurface = Color(0xCC1A1926); // Dark card 80%
  static const Color glassBorderLight = Color(0x40FFFFFF); // White border 25%
  static const Color glassBorderDark = Color(0x1AFFFFFF);  // Dark border 10%
  static const Color glassOverlayLight = Color(0x0D000000);
  static const Color glassOverlayDark = Color(0x33000000);

  // ==========================================
  // Shimmer Skeleton Colors
  // ==========================================
  static const Color shimmerBase = Color(0xFFE5E7EB);
  static const Color shimmerHighlight = Color(0xFFF9FAFB);
  static const Color shimmerBaseDark = Color(0xFF1A1926);
  static const Color shimmerHighlightDark = Color(0xFF2E2C3D);

  // ==========================================
  // Navigation Bar
  // ==========================================
  static const Color navBarLight = Color(0xFFFFFFFF);
  static const Color navBarDark = Color(0xFF12111A);
  static const Color navIndicatorLight = Color(0xFFEEF0FD);  // Faint purple active tab
  static const Color navIndicatorDark = Color(0xFF2A283D);   // Dark active tab indicator

  // ==========================================
  // Stat Card Gradients
  // ==========================================
  static const Color statCardBlue = Color(0xFF3B82F6);
  static const Color statCardPurple = Color(0xFF8B5CF6);
  static const Color statCardGreen = Color(0xFF10B981);
  static const Color statCardOrange = Color(0xFFF59E0B);

  // ==========================================
  // Premium Gradients
  // ==========================================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8C85FF), Color(0xFF6C63FF)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF4F46E5)],
  );

  static const LinearGradient alertGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFCA5A5), Color(0xFFEF4444)],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1926), Color(0xFF12111A)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF4F46E5), Color(0xFF312E81)],
  );

  static const LinearGradient dashboardHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF4F46E5)],
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

  // ==========================================
  // Phase Migration Compatibility Aliases
  // ==========================================
  static const Color primaryTeal = primaryPurple;
  static const Color primaryTealLight = primaryPurpleLight;
  static const Color primaryTealDark = primaryPurpleDark;
  static const Color secondaryMint = secondaryIndigo;
}

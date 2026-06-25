import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // ==========================================
  // 8px Grid Base Values
  // ==========================================
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
  static const double xxxxl = 64.0;

  // ==========================================
  // Semantic Spacing Aliases
  // ==========================================
  /// Standard horizontal page padding (20px)
  static const double pageHorizontal = 20.0;

  /// Standard section spacing between major blocks
  static const double sectionSpacing = 28.0;

  /// Bottom navigation bar height
  static const double bottomNavHeight = 80.0;

  /// Floating Action Button size
  static const double fabSize = 56.0;

  /// Card inner content padding
  static const double cardPadding = 16.0;

  // ==========================================
  // Border Radius
  // ==========================================
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusXxl = 32.0;
  static const double radiusRound = 999.0;

  static final BorderRadius borderRadiusXs = BorderRadius.circular(radiusXs);
  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);
  static final BorderRadius borderRadiusXxl = BorderRadius.circular(radiusXxl);
  static final BorderRadius borderRadiusRound = BorderRadius.circular(radiusRound);

  // Top-only radius for bottom sheets
  static final BorderRadius borderRadiusTopXl = const BorderRadius.vertical(
    top: Radius.circular(radiusXl),
  );
  static final BorderRadius borderRadiusTopXxl = const BorderRadius.vertical(
    top: Radius.circular(radiusXxl),
  );

  // ==========================================
  // Pre-configured EdgeInsets
  // ==========================================
  static const EdgeInsets edgeInsetsAll4 = EdgeInsets.all(xs);
  static const EdgeInsets edgeInsetsAll8 = EdgeInsets.all(sm);
  static const EdgeInsets edgeInsetsAll12 = EdgeInsets.all(md);
  static const EdgeInsets edgeInsetsAll16 = EdgeInsets.all(lg);
  static const EdgeInsets edgeInsetsAll20 = EdgeInsets.all(pageHorizontal);
  static const EdgeInsets edgeInsetsAll24 = EdgeInsets.all(xl);
  static const EdgeInsets edgeInsetsAll32 = EdgeInsets.all(xxl);

  static const EdgeInsets edgeInsetsHorizontal16 = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets edgeInsetsHorizontal20 = EdgeInsets.symmetric(horizontal: pageHorizontal);
  static const EdgeInsets edgeInsetsHorizontal24 = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets edgeInsetsVertical8 = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets edgeInsetsVertical12 = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets edgeInsetsVertical16 = EdgeInsets.symmetric(vertical: lg);

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: pageHorizontal);
  static const EdgeInsets cardPaddingAll = EdgeInsets.all(cardPadding);
  static const EdgeInsets edgeInsetsCard = EdgeInsets.symmetric(horizontal: lg, vertical: md);

  // ==========================================
  // Pre-configured Spacers
  // ==========================================
  static const SizedBox vGap2 = SizedBox(height: xxs);
  static const SizedBox vGap4 = SizedBox(height: xs);
  static const SizedBox vGap8 = SizedBox(height: sm);
  static const SizedBox vGap12 = SizedBox(height: md);
  static const SizedBox vGap16 = SizedBox(height: lg);
  static const SizedBox vGap20 = SizedBox(height: pageHorizontal);
  static const SizedBox vGap24 = SizedBox(height: xl);
  static const SizedBox vGap28 = SizedBox(height: sectionSpacing);
  static const SizedBox vGap32 = SizedBox(height: xxl);
  static const SizedBox vGap48 = SizedBox(height: xxxl);
  static const SizedBox vGap64 = SizedBox(height: xxxxl);

  static const SizedBox hGap2 = SizedBox(width: xxs);
  static const SizedBox hGap4 = SizedBox(width: xs);
  static const SizedBox hGap8 = SizedBox(width: sm);
  static const SizedBox hGap12 = SizedBox(width: md);
  static const SizedBox hGap16 = SizedBox(width: lg);
  static const SizedBox hGap20 = SizedBox(width: pageHorizontal);
  static const SizedBox hGap24 = SizedBox(width: xl);
  static const SizedBox hGap32 = SizedBox(width: xxl);
}

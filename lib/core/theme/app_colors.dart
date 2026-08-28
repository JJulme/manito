import 'package:flutter/material.dart';

/// App Color Palette adhering to 60-30-10 Minimalist Design Principle
class AppColors {
  AppColors._();

  // 60% Background & Surfaces (Light)
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceLow = Color(0xFFF8FAFC);
  static const Color card = Color(0xFFFFFFFF);

  // 30% Text & Grayscale (Light)
  static const Color textPrimary = Color(0xFF222222);
  static const Color textSecondary = Color(0xFF767676);
  static const Color textDisabled = Color(0xFFCCCCCC);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // Dark Mode - 60% Background & Surfaces
  static const Color darkBackground = Color(0xFF121214);
  static const Color darkSurface = Color(0xFF1E1E24);
  static const Color darkSurfaceLow = Color(0xFF26262E);
  static const Color darkCard = Color(0xFF1E1E24);

  // Dark Mode - 30% Text & Grayscale
  static const Color darkTextPrimary = Color(0xFFF4F4F6);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkTextDisabled = Color(0xFF52525B);
  static const Color darkBorder = Color(0xFF2E2E38);
  static const Color darkDivider = Color(0xFF26262E);

  // 10% Point Accent (Yellow)
  static const Color primary = Color(0xFFFFD700);
  static const Color primaryLight = Color(0xFFFFF3A3);
  static const Color primaryDark = Color(0xFFE6C200);
  static const Color darkPrimaryLight = Color(0xFF383210);

  // Special Status & Emergency Colors
  static const Color timerUrgent = Color(0xFF8B0000); // Countdown Dark Red
  static const Color statusGreen = Color(0xFF22C55E); // '✔️' Accepted
  static const Color statusYellow = Color(0xFFFACC15); // '-' Waiting
  static const Color statusOrange = Color(0xFFF97316); // Guess / In-progress
  static const Color statusRed = Color(0xFFEF4444); // 'X' Rejected
  static const Color error = Color(0xFFEF4444); // Error / Red Dot Badge
  static const Color success = Color(0xFF22C55E); // Success / Green

  // Dynamic Theme Helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color backgroundOf(BuildContext context) =>
      isDark(context) ? darkBackground : background;
  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? darkSurface : surface;
  static Color surfaceLowOf(BuildContext context) =>
      isDark(context) ? darkSurfaceLow : surfaceLow;
  static Color cardOf(BuildContext context) =>
      isDark(context) ? darkCard : card;
  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;
  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;
  static Color textDisabledOf(BuildContext context) =>
      isDark(context) ? darkTextDisabled : textDisabled;
  static Color borderOf(BuildContext context) =>
      isDark(context) ? darkBorder : border;
  static Color dividerOf(BuildContext context) =>
      isDark(context) ? darkDivider : divider;
  static Color primaryLightOf(BuildContext context) =>
      isDark(context) ? darkPrimaryLight : primaryLight;
  static Color primaryDarkOf(BuildContext context) =>
      isDark(context) ? primary : primaryDark;

  // Shadow Styles
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF64748B).withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> cardShadowOf(BuildContext context) => isDark(context)
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ]
      : cardShadow;

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: const Color(0xFF64748B).withValues(alpha: 0.14),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> elevatedShadowOf(BuildContext context) => isDark(context)
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ]
      : elevatedShadow;
}

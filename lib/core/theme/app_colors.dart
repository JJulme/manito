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

  static AppColorsExtension of(BuildContext context) =>
      Theme.of(context).extension<AppColorsExtension>() ??
      (isDark(context) ? AppColorsExtension.dark : AppColorsExtension.light);

  static Color backgroundOf(BuildContext context) => of(context).background;
  static Color surfaceOf(BuildContext context) => of(context).surface;
  static Color surfaceLowOf(BuildContext context) => of(context).surfaceLow;
  static Color cardOf(BuildContext context) => of(context).card;
  static Color textPrimaryOf(BuildContext context) => of(context).textPrimary;
  static Color textSecondaryOf(BuildContext context) => of(context).textSecondary;
  static Color textDisabledOf(BuildContext context) => of(context).textDisabled;
  static Color borderOf(BuildContext context) => of(context).border;
  static Color dividerOf(BuildContext context) => of(context).divider;
  static Color primaryLightOf(BuildContext context) => of(context).primaryLight;
  static Color primaryDarkOf(BuildContext context) => of(context).primaryDark;

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

/// Material 3 ThemeExtension for Type-safe and smooth color themes
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color background;
  final Color surface;
  final Color surfaceLow;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color border;
  final Color divider;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;

  const AppColorsExtension({
    required this.background,
    required this.surface,
    required this.surfaceLow,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.border,
    required this.divider,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
  });

  static const light = AppColorsExtension(
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceLow: AppColors.surfaceLow,
    card: AppColors.card,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textDisabled: AppColors.textDisabled,
    border: AppColors.border,
    divider: AppColors.divider,
    primary: AppColors.primary,
    primaryLight: AppColors.primaryLight,
    primaryDark: AppColors.primaryDark,
  );

  static const dark = AppColorsExtension(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceLow: AppColors.darkSurfaceLow,
    card: AppColors.darkCard,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textDisabled: AppColors.darkTextDisabled,
    border: AppColors.darkBorder,
    divider: AppColors.darkDivider,
    primary: AppColors.primary,
    primaryLight: AppColors.darkPrimaryLight,
    primaryDark: AppColors.primaryDark,
  );

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? surface,
    Color? surfaceLow,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? border,
    Color? divider,
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceLow: surfaceLow ?? this.surfaceLow,
      card: card ?? this.card,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceLow: Color.lerp(surfaceLow, other.surfaceLow, t) ?? surfaceLow,
      card: Color.lerp(card, other.card, t) ?? card,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t) ?? textDisabled,
      border: Color.lerp(border, other.border, t) ?? border,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t) ?? primaryLight,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t) ?? primaryDark,
    );
  }
}

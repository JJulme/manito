import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const TextStyle logo = TextStyle(
    fontFamily: 'CookieRun',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineXl = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle headlineLg = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static const TextStyle headlineMd = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle titleLg = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle titleMd = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle titleMedium = titleMd;

  static const TextStyle titleSm = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle titleSmall = titleSm;

  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = bodyMd;

  static const TextStyle bodySm = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle labelMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle labelSm = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle timerDisplay = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.timerUrgent,
    letterSpacing: 1.0,
  );
}

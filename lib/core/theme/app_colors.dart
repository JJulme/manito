import 'package:flutter/material.dart';

/// App Color Palette adhering to 60-30-10 Minimalist Design Principle
class AppColors {
  AppColors._();

  // 60% Background & Surfaces
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceLow = Color(0xFFF8FAFC);
  static const Color card = Color(0xFFFFFFFF);

  // 30% Text & Grayscale
  static const Color textPrimary = Color(0xFF222222);
  static const Color textSecondary = Color(0xFF767676);
  static const Color textDisabled = Color(0xFFCCCCCC);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // 10% Point Accent (Yellow)
  static const Color primary = Color(0xFFFFD700);
  static const Color primaryLight = Color(0xFFFFF3A3);
  static const Color primaryDark = Color(0xFFE6C200);

  // Special Status & Emergency Colors
  static const Color timerUrgent = Color(0xFF8B0000); // Countdown Dark Red
  static const Color statusGreen = Color(0xFF22C55E); // '✔️' Accepted
  static const Color statusYellow = Color(0xFFFACC15); // '-' Waiting
  static const Color statusOrange = Color(0xFFF97316); // Guess / In-progress
  static const Color statusRed = Color(0xFFEF4444); // 'X' Rejected
  static const Color error = Color(0xFFEF4444); // Error / Red Dot Badge
  static const Color success = Color(0xFF22C55E); // Success / Green

  // Shadow Styles
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF64748B).withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: const Color(0xFF64748B).withValues(alpha: 0.14),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}

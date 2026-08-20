import 'package:flutter/material.dart';
import 'package:manito/main.dart';

const Color kSuccess = Color(0xFF4CAF50);
const Color kOffBlack = Color(0xFF212121);
const Color kYellow = Color(0xFFFFD600);
const Color kDeepOrange = Color(0xFFFF5722);
const Color kDarkWalnut = Color(0xFF342D21);
const Color kWhite = Color(0xFFFAFAFA);
const Color kGrey = Color(0x7DF9F9F9);

final ColorScheme lightColorScheme = const ColorScheme(
  brightness: Brightness.light,
  tertiary: kYellow,
  primary: Color(0xFF3A3A3A),
  onPrimary: Colors.white,
  secondary: Color(0xFF5A5A5A),
  onSecondary: Colors.white,
  surface: Color(0xFFFFFFFF),
  onSurface: Color(0xFF1A1A1A),
  error: Colors.red,
  onError: Colors.white,
  primaryContainer: Color(0xFFEDEDED),
  onPrimaryContainer: Colors.black,
  secondaryContainer: Color(0xFFF1F1F1),
  onSecondaryContainer: Colors.black,
);

final ColorScheme darkColorScheme = const ColorScheme(
  brightness: Brightness.dark,
  tertiary: kGrey,
  onTertiary: Colors.black,
  primary: Color(0xFFDDDDDD),
  onPrimary: Color(0xFF1A1A1A),
  secondary: Color(0xFFBBBBBB),
  onSecondary: Color(0xFF1A1A1A),
  surface: Color(0xFF1E1E1E),
  onSurface: Color(0xFFEFEFEF),
  error: Color(0xFFF44747),
  onError: Colors.black,
  primaryContainer: Color(0xFF2A2A2A),
  onPrimaryContainer: Color(0xFFEFEFEF),
  secondaryContainer: Color(0xFF262626),
  onSecondaryContainer: Color(0xFFEFEFEF),
);

const Map<String, double> kBaseFontSizes = {
  'displayLarge': 57.0,
  'displayMedium': 45.0,
  'displaySmall': 36.0,
  'headlineLarge': 32.0,
  'headlineMedium': 28.0,
  'headlineSmall': 24.0,
  'titleLarge': 22.0,
  'titleMedium': 16.0,
  'titleSmall': 14.0,
  'bodyLarge': 16.0,
  'bodyMedium': 14.0,
  'bodySmall': 12.0,
  'labelLarge': 14.0,
  'labelMedium': 12.0,
  'labelSmall': 11.0,
};

ThemeData lightTheme = commonStyle(
  ThemeData(brightness: Brightness.light, colorScheme: lightColorScheme),
);

ThemeData darkTheme = commonStyle(
  ThemeData(brightness: Brightness.dark, colorScheme: darkColorScheme),
);

ThemeData commonStyle(ThemeData baseTheme) {
  TextStyle getScaledTextStyle(
    double baseSize, {
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextStyle(
      color: baseTheme.colorScheme.onSurface,
      fontSize: baseSize * width / 400,
      fontWeight: fontWeight,
    );
  }

  return baseTheme.copyWith(
    dividerTheme: DividerThemeData(
      space: 0.12 * width,
      thickness: 0.025 * width,
      color: baseTheme.colorScheme.primaryContainer,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: kOffBlack,
        backgroundColor: kYellow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0.02 * width),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0.02 * width),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: baseTheme.colorScheme.primaryContainer,
    ),
    textTheme: TextTheme(
      displayLarge: getScaledTextStyle(kBaseFontSizes['displayLarge']!),
      displayMedium: getScaledTextStyle(kBaseFontSizes['displayMedium']!),
      displaySmall: getScaledTextStyle(kBaseFontSizes['displaySmall']!),

      headlineLarge: getScaledTextStyle(kBaseFontSizes['headlineLarge']!),
      headlineMedium: getScaledTextStyle(kBaseFontSizes['headlineMedium']!),
      headlineSmall: getScaledTextStyle(kBaseFontSizes['headlineSmall']!),

      titleLarge: getScaledTextStyle(kBaseFontSizes['titleLarge']!),
      titleMedium: getScaledTextStyle(kBaseFontSizes['titleMedium']!),
      titleSmall: getScaledTextStyle(kBaseFontSizes['titleSmall']!),

      bodyLarge: getScaledTextStyle(kBaseFontSizes['bodyLarge']!),
      bodyMedium: getScaledTextStyle(kBaseFontSizes['bodyMedium']!),
      bodySmall: getScaledTextStyle(kBaseFontSizes['bodySmall']!),

      labelLarge: getScaledTextStyle(kBaseFontSizes['labelLarge']!),
      labelMedium: getScaledTextStyle(kBaseFontSizes['labelMedium']!),
      labelSmall: getScaledTextStyle(kBaseFontSizes['labelSmall']!),
    ),
  );
}

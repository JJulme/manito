import 'package:flutter/material.dart';
import 'package:manito/main.dart';
// import 'package:manito/core/constants.dart';
// import 'package:manito/main.dart';

// var themeData = ThemeData(
//   useMaterial3: true,
//   primarySwatch: Colors.amber,
//   colorScheme: ColorScheme.fromSeed(seedColor: kDarkWalnut),
//   // 앱바 설정
//   appBarTheme: AppBarTheme(
//     color: Colors.white,
//     surfaceTintColor: Colors.white,
//     elevation: 0,
//     iconTheme: IconThemeData(size: 0.05 * width),
//     toolbarHeight: 0.155 * width,
//   ),
//   // 바텀 네비 설정
//   bottomNavigationBarTheme: BottomNavigationBarThemeData(
//     selectedItemColor: Colors.black87,
//     unselectedItemColor: Colors.black26,
//     backgroundColor: Colors.white,
//     // 라벨 숨기기
//     showSelectedLabels: true,
//     showUnselectedLabels: true,
//     selectedLabelStyle: TextStyle(fontSize: 0.03 * width),
//     // 움직임 효과 제거
//     type: BottomNavigationBarType.fixed,
//   ),
//   // 바텀 시트 설정
//   bottomSheetTheme: BottomSheetThemeData(backgroundColor: Colors.white),
//   bottomAppBarTheme: BottomAppBarTheme(
//     color: Colors.white,
//     height: 0.2 * width,
//     padding: EdgeInsets.zero,
//   ),
//   // 기본 배경색 설정
//   scaffoldBackgroundColor: Colors.white,
//   // 기본 아이콘 설정
//   iconTheme: IconThemeData(size: 0.065 * width),
//   // 팝업 메뉴 버튼 설정
//   popupMenuTheme: PopupMenuThemeData(color: Colors.white),
//   // 디바이더 설정
//   dividerTheme: DividerThemeData(
//     color: Colors.grey[200],
//     space: 0.12 * width,
//     thickness: 0.025 * width,
//   ),
//   // 다이얼로그 테마 설정
//   dialogTheme: DialogTheme(
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(0.02 * width),
//     ),
//   ),
//   // 텍스트 입력 설정
//   inputDecorationTheme: InputDecorationTheme(
//     border: OutlineInputBorder(
//       borderRadius: BorderRadius.circular(0.02 * width),
//     ),
//   ),
//   // 입체 버튼 설정
//   elevatedButtonTheme: ElevatedButtonThemeData(
//     style: ElevatedButton.styleFrom(
//       foregroundColor: Colors.black,
//       backgroundColor: kYellow,
//       // foregroundColor: kDarkWalnut,
//       // backgroundColor: kCocoaCream,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(0.02 * width),
//       ),
//       textStyle: TextStyle(color: kCocoaCream, fontSize: 0.05 * width),
//     ),
//   ),
//   // 테두리 버튼 설정
//   outlinedButtonTheme: OutlinedButtonThemeData(
//     style: OutlinedButton.styleFrom(
//       foregroundColor: Colors.black,
//       backgroundColor: Colors.white,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(0.02 * width),
//       ),
//     ),
//   ),
//   // 텍스트 설정
//   textTheme: TextTheme(
//     /// 로그인 화면
//     displayMedium: TextStyle(
//       fontSize: 0.15 * width,
//       color: kOffBlack,
//       fontWeight: FontWeight.bold,
//     ),
//     displaySmall: TextStyle(
//       fontSize: 0.09 * width,
//       color: kOffBlack,
//       fontWeight: FontWeight.bold,
//     ),

//     /// 앱바 타이틀
//     headlineLarge: TextStyle(
//       fontSize: 0.056 * width,
//       color: kOffBlack,
//       fontWeight: FontWeight.bold,
//     ),
//     headlineMedium: TextStyle(
//       fontSize: 0.054 * width,
//       color: kOffBlack,
//       fontWeight: FontWeight.bold,
//     ),
//     headlineSmall: TextStyle(
//       fontSize: 0.052 * width,
//       color: kOffBlack,
//       fontWeight: FontWeight.bold,
//     ),
//     // 강조
//     titleLarge: TextStyle(
//       fontSize: 0.054 * width,
//       color: kOffBlack,
//       fontWeight: FontWeight.bold,
//     ),
//     titleMedium: TextStyle(
//       fontSize: 0.052 * width,
//       color: kOffBlack,
//       fontWeight: FontWeight.bold,
//     ),
//     titleSmall: TextStyle(
//       fontSize: 0.05 * width,
//       color: kOffBlack,
//       fontWeight: FontWeight.bold,
//     ),

//     /// 기본 대분류
//     bodyLarge: TextStyle(
//       fontSize: 0.046 * width,
//       color: kOffBlack,
//       fontWeight: FontWeight.normal,
//     ),

//     /// 기본 내용
//     bodyMedium: TextStyle(
//       fontSize: 0.044 * width,
//       color: kOffBlack,
//       fontWeight: FontWeight.normal,
//     ),

//     /// 친구 상태 메시지
//     bodySmall: TextStyle(
//       fontSize: 0.042 * width,
//       color: kOffBlack,
//       fontWeight: FontWeight.normal,
//     ),
//     // 라벨
//     labelLarge: TextStyle(
//       fontSize: 0.034 * width,
//       color: kGrey,
//       fontWeight: FontWeight.normal,
//     ),
//     labelMedium: TextStyle(
//       fontSize: 0.032 * width,
//       color: kGrey,
//       fontWeight: FontWeight.normal,
//     ),
//     labelSmall: TextStyle(
//       fontSize: 0.03 * width,
//       color: kGrey,
//       fontWeight: FontWeight.normal,
//     ),
//   ),
// );

// 님의 색상 변수 (이전에 사용했던 것을 가정)
const Color kSuccess = Color(0xFF4CAF50);
const Color kOffBlack = Color(0xFF212121);
const Color kYellow = Color(0xFFFFD600);
const Color kDeepOrange = Color(0xFFFF5722);
const Color kDarkWalnut = Color(0xFF342D21); // 메인 테마의 중립 색상으로 사용
const Color kWhite = Color(0xFFFAFAFA);
const Color kGrey = Color(0x7DF9F9F9);
// ...

final ColorScheme lightColorScheme = const ColorScheme(
  brightness: Brightness.light,
  tertiary: kYellow,
  // 앱의 주요 색상 (버튼/포커스/아이콘 등)
  primary: Color(0xFF3A3A3A),
  onPrimary: Colors.white,
  // 서브 액션, 서브 정보 색상
  secondary: Color(0xFF5A5A5A),
  onSecondary: Colors.white,
  // 카드 / 컨테이너 / 버튼 배경
  surface: Color(0xFFFFFFFF), // 컨테이너
  onSurface: Color(0xFF1A1A1A),
  // 에러
  error: Colors.red,
  onError: Colors.white,
  // primaryContainer → 강조 카드, 정보 카드
  primaryContainer: Color(0xFFEDEDED),
  onPrimaryContainer: Colors.black,
  // secondaryContainer → 서브 카드, 설정 섹션 등
  secondaryContainer: Color(0xFFF1F1F1),
  onSecondaryContainer: Colors.black,
);

final ColorScheme darkColorScheme = const ColorScheme(
  brightness: Brightness.dark,
  tertiary: kGrey,
  onTertiary: Colors.black,
  // 앱의 주요 색상 (버튼/포커스/아이콘 등)
  primary: Color(0xFFDDDDDD), // 밝은 회색 톤
  onPrimary: Color(0xFF1A1A1A), // primary 위 글자색
  // 서브 액션, 서브 정보 색상
  secondary: Color(0xFFBBBBBB),
  onSecondary: Color(0xFF1A1A1A),
  // 카드 / 컨테이너 / 버튼 배경
  surface: Color(0xFF1E1E1E), // 배경보다 약간 밝은 컨테이너
  onSurface: Color(0xFFEFEFEF), // 텍스트 색
  // 에러
  error: Color(0xFFF44747), // 디스코드 스타일 레드
  onError: Colors.black,
  // primaryContainer → 강조 카드, 정보 카드
  primaryContainer: Color(0xFF2A2A2A),
  onPrimaryContainer: Color(0xFFEFEFEF),
  // secondaryContainer → 서브 카드, 설정 섹션 등
  secondaryContainer: Color(0xFF262626),
  onSecondaryContainer: Color(0xFFEFEFEF),
);

// Material 3 기반의 기본 폰트 크기 정의
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
  // 기본 스타일을 복사하여 모든 폰트 크기에 scaleFactor를 적용합니다.
  TextStyle getScaledTextStyle(
    double baseSize, {
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextStyle(
      color: baseTheme.colorScheme.onSurface,
      fontSize: baseSize * width / 400, // 너비에 따른 스케일링이 적용 (기준 너비 400)
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

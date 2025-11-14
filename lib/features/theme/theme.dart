import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:manito/core/constants.dart';
import 'package:manito/main.dart';

var themeData = ThemeData(
  useMaterial3: true,
  primarySwatch: Colors.amber,
  colorScheme: ColorScheme.fromSeed(seedColor: kDarkWalnut),
  // 앱바 설정
  appBarTheme: AppBarTheme(
    color: Colors.white,
    surfaceTintColor: Colors.white,
    elevation: 0,
    iconTheme: IconThemeData(size: 0.05 * width),
    toolbarHeight: 0.155 * width,
  ),
  // 바텀 네비 설정
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    selectedItemColor: Colors.black87,
    unselectedItemColor: Colors.black26,
    backgroundColor: Colors.white,
    // 라벨 숨기기
    showSelectedLabels: true,
    showUnselectedLabels: true,
    selectedLabelStyle: TextStyle(fontSize: 0.03 * width),
    // 움직임 효과 제거
    type: BottomNavigationBarType.fixed,
  ),
  // 바텀 시트 설정
  bottomSheetTheme: BottomSheetThemeData(backgroundColor: Colors.white),
  bottomAppBarTheme: BottomAppBarTheme(
    color: Colors.white,
    height: 0.2 * width,
    padding: EdgeInsets.zero,
  ),
  // 기본 배경색 설정
  scaffoldBackgroundColor: Colors.white,
  // 기본 아이콘 설정
  iconTheme: IconThemeData(size: 0.065 * width),
  // 팝업 메뉴 버튼 설정
  popupMenuTheme: PopupMenuThemeData(color: Colors.white),
  // 디바이더 설정
  dividerTheme: DividerThemeData(
    color: Colors.grey[200],
    space: 0.12 * width,
    thickness: 0.025 * width,
  ),
  // 다이얼로그 테마 설정
  dialogTheme: DialogTheme(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(0.02 * width),
    ),
  ),
  // 텍스트 입력 설정
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(0.02 * width),
    ),
  ),
  // 입체 버튼 설정
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: kYellow,
      // foregroundColor: kDarkWalnut,
      // backgroundColor: kCocoaCream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0.02 * width),
      ),
      textStyle: TextStyle(color: kCocoaCream, fontSize: 0.05 * width),
    ),
  ),
  // 테두리 버튼 설정
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0.02 * width),
      ),
    ),
  ),
  // 텍스트 설정
  textTheme: TextTheme(
    /// 로그인 화면
    displayMedium: TextStyle(
      fontSize: 0.15 * width,
      color: kOffBlack,
      fontWeight: FontWeight.bold,
    ),
    displaySmall: TextStyle(
      fontSize: 0.09 * width,
      color: kOffBlack,
      fontWeight: FontWeight.bold,
    ),

    /// 앱바 타이틀
    headlineLarge: TextStyle(
      fontSize: 0.056 * width,
      color: kOffBlack,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      fontSize: 0.054 * width,
      color: kOffBlack,
      fontWeight: FontWeight.bold,
    ),
    headlineSmall: TextStyle(
      fontSize: 0.052 * width,
      color: kOffBlack,
      fontWeight: FontWeight.bold,
    ),
    // 강조
    titleLarge: TextStyle(
      fontSize: 0.054 * width,
      color: kOffBlack,
      fontWeight: FontWeight.bold,
    ),
    titleMedium: TextStyle(
      fontSize: 0.052 * width,
      color: kOffBlack,
      fontWeight: FontWeight.bold,
    ),
    titleSmall: TextStyle(
      fontSize: 0.05 * width,
      color: kOffBlack,
      fontWeight: FontWeight.bold,
    ),

    /// 기본 대분류
    bodyLarge: TextStyle(
      fontSize: 0.046 * width,
      color: kOffBlack,
      fontWeight: FontWeight.normal,
    ),

    /// 기본 내용
    bodyMedium: TextStyle(
      fontSize: 0.044 * width,
      color: kOffBlack,
      fontWeight: FontWeight.normal,
    ),

    /// 친구 상태 메시지
    bodySmall: TextStyle(
      fontSize: 0.042 * width,
      color: kOffBlack,
      fontWeight: FontWeight.normal,
    ),
    // 라벨
    labelLarge: TextStyle(
      fontSize: 0.034 * width,
      color: kGrey,
      fontWeight: FontWeight.normal,
    ),
    labelMedium: TextStyle(
      fontSize: 0.032 * width,
      color: kGrey,
      fontWeight: FontWeight.normal,
    ),
    labelSmall: TextStyle(
      fontSize: 0.03 * width,
      color: kGrey,
      fontWeight: FontWeight.normal,
    ),
  ),
);

final ThemeData themeLight = FlexThemeData.light(
  scheme: FlexScheme.shark,
  surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
  blendLevel: 9,
  subThemesData: const FlexSubThemesData(),
  keyColors: const FlexKeyColors(
    useTertiary: true,
    keepPrimary: true,
    keepSecondary: true,
    keepPrimaryContainer: true,
  ),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
);

final ThemeData themeDark = FlexThemeData.dark(
  scheme: FlexScheme.shark,
  surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
  blendLevel: 15,
  subThemesData: const FlexSubThemesData(),
  keyColors: const FlexKeyColors(
    useTertiary: true,
    keepPrimary: true,
    keepSecondary: true,
    keepPrimaryContainer: true,
  ),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
);

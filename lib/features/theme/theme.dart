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

ThemeData lightTheme = commonStyle(
  ThemeData(brightness: Brightness.light, colorScheme: lightColorScheme),
);

ThemeData darkTheme = commonStyle(
  ThemeData(brightness: Brightness.dark, colorScheme: darkColorScheme),
);

ThemeData commonStyle(ThemeData baseTheme) {
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
  );
}
// 2. 테마 생성 함수
// ThemeData createCustomTheme({required double width, required bool isDark}) {
//   // 기본 테마 생성 (색상은 여기서 결정됨)
//   final ThemeData baseTheme =
//       isDark
//           ? FlexThemeData.dark(
//             colors: myColors,
//             surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
//             blendLevel: 15,
//             subThemesData: const FlexSubThemesData(blendOnLevel: 20),
//             keyColors: const FlexKeyColors(
//               useTertiary: true,
//               keepPrimary: true,
//               keepSecondary: true,
//               keepPrimaryContainer: true,
//             ),
//             visualDensity: FlexColorScheme.comfortablePlatformDensity,
//             useMaterial3: true,
//           )
//           : FlexThemeData.light(
//             colors: myColors, // [변경] scheme 대신 colors 사용
//             surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
//             blendLevel: 9,
//             subThemesData: const FlexSubThemesData(
//               blendOnLevel: 10,
//               blendOnColors: false,
//             ),
//             keyColors: const FlexKeyColors(
//               useTertiary: true,
//               keepPrimary: true,
//               keepSecondary: true,
//               keepPrimaryContainer: false,
//             ),
//             visualDensity: FlexColorScheme.comfortablePlatformDensity,
//             useMaterial3: true,
//           );

//   // 3. 디테일 설정 덮어쓰기 (색상 코드 전부 제거됨)
//   return baseTheme.copyWith(
//     // [앱바] 색상은 위 appBarStyle에서 처리됨
//     appBarTheme: baseTheme.appBarTheme.copyWith(
//       elevation: 0,
//       toolbarHeight: 0.155 * width,
//       iconTheme: IconThemeData(size: 0.05 * width), // 색상은 자동
//       centerTitle: true, // (선택사항)
//     ),

//     // [바텀 네비게이션] 색상은 Primary/Secondary 설정에 따라 자동 적용
//     bottomNavigationBarTheme: BottomNavigationBarThemeData(
//       // 라벨 보이기 설정
//       showSelectedLabels: true,
//       showUnselectedLabels: true,
//       // 폰트 크기만 남김
//       selectedLabelStyle: TextStyle(fontSize: 0.03 * width),
//       unselectedLabelStyle: TextStyle(
//         fontSize: 0.03 * width,
//       ), // 추가: 선택 안된 것도 크기 맞춤
//       type: BottomNavigationBarType.fixed,
//     ),

//     // [바텀 앱바]
//     bottomAppBarTheme: BottomAppBarTheme(
//       height: 0.2 * width,
//       padding: EdgeInsets.zero,
//     ),

//     // [기본 아이콘]
//     iconTheme: baseTheme.iconTheme.copyWith(size: 0.065 * width),

//     // [디바이더] 색상은 테마의 dividerColor를 따름
//     dividerTheme: DividerThemeData(
//       space: 0.12 * width,
//       thickness: 0.025 * width,
//     ),

//     // [다이얼로그] 모양만 남김
//     dialogTheme: DialogTheme(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(0.02 * width),
//       ),
//     ),

//     // [텍스트 입력창] 모양만 남김
//     inputDecorationTheme: InputDecorationTheme(
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(0.02 * width),
//       ),
//     ),

//     // [입체 버튼] 색상은 PrimaryColor를 따름
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(0.02 * width),
//         ),
//         textStyle: TextStyle(fontSize: 0.05 * width), // 색상 제거
//       ),
//     ),

//     // [테두리 버튼]
//     outlinedButtonTheme: OutlinedButtonThemeData(
//       style: OutlinedButton.styleFrom(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(0.02 * width),
//         ),
//       ),
//     ),
//   );
// }

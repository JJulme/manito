import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:manito/constants.dart';
import 'package:manito/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:manito/firebase_options.dart';

void main() async {
  // 웹바인딩 설정
  // WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // 런처 스플래쉬 화면 설정
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // FCM 설정
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Admob 설정
  MobileAds.instance.initialize();
  // 다국어 패키지 초기화
  await EasyLocalization.ensureInitialized();
  // .env 변수 가져오기
  await dotenv.load(fileName: '.env');
  // supabase 연결
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  // 한국어 설정
  timeago.setLocaleMessages('ko', timeago.KoMessages());
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ko', 'KR')],
      path: 'assets/translations',
      child: const Manito(),
    ),
  );
}

class Manito extends StatefulWidget {
  const Manito({super.key});

  @override
  State<Manito> createState() => _ManitoState();
}

class _ManitoState extends State<Manito> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    // 테마 설정
    var themeData = ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.amber,
      // primaryColor: kSunsetPeach,
      // primaryColorLight: kSunsetPeachLight,
      // primaryColorDark: kSunsetPeachDark,
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
          backgroundColor: Colors.yellowAccent[700],
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

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      // 다국어 설정
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      // 테마 설정
      theme: themeData,
      home: SplashScreen(),
    );
  }
}

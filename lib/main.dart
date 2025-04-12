import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:manito/constants.dart';
import 'package:manito/firebase_handler.dart';
import 'package:manito/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:manito/firebase_options.dart';

void main() async {
  // 웹바인딩 설정
  WidgetsFlutterBinding.ensureInitialized();
  // FCM 설정
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // FCM 백그라운드 핸들러 설정
  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  // Admob 설정
  MobileAds.instance.initialize();
  // .env 변수 가져오기
  await dotenv.load(fileName: '.env');
  // supabase 연결
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  KakaoSdk.init(
    nativeAppKey: dotenv.env['KAKAO_APP_KEY']
  );
  // 한국어 설정
  timeago.setLocaleMessages('ko', timeago.KoMessages());
  runApp(const Manito());
}

class Manito extends StatefulWidget {
  const Manito({super.key});

  @override
  State<Manito> createState() => _ManitoState();
}

class _ManitoState extends State<Manito> {
  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double di = sqrt(pow(MediaQuery.of(context).size.width, 2) +
        pow(MediaQuery.of(context).size.height, 2));
    // 테마 설정
    var themeData = ThemeData(
      useMaterial3: true,
      primaryColor: kSunsetPeach,
      primaryColorLight: kSunsetPeachLight,
      primaryColorDark: kSunsetPeachDark,
      // 앱바 설정
      appBarTheme: AppBarTheme(
        color: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(size: 0.032 * di),
      ),
      // 바텀 시트 설정
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
      ),
      bottomAppBarTheme: BottomAppBarTheme(
        color: Colors.white,
      ),
      // 기본 배경색 설정
      scaffoldBackgroundColor: Colors.white,
      iconTheme: IconThemeData(size: 0.07 * w),
      // 팝업 메뉴 버튼 설정
      popupMenuTheme: PopupMenuThemeData(color: Colors.white),
      // 다이얼로그 테마 설정
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0.01 * di),
        ),
      ),
      // 텍스트 입력 설정
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0.01 * di),
        ),
      ),
      // 입체 버튼 설정
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.yellowAccent[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0.01 * di),
          ),
        ),
      ),
      // 테두리 버튼 설정
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kDarkWalnut,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0.01 * di),
          ),
        ),
      ),
      // 텍스트 설정
      textTheme: TextTheme(
        /// 로그인 화면
        displayMedium: TextStyle(
          fontSize: 0.05 * di,
          color: kOffBlack,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          fontSize: 0.03 * di,
          color: kOffBlack,
          fontWeight: FontWeight.bold,
        ),

        /// 앱바 타이틀
        headlineLarge: TextStyle(
          fontSize: 0.056 * w,
          color: kOffBlack,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          fontSize: 0.054 * w,
          color: kOffBlack,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          fontSize: 0.052 * w,
          color: kOffBlack,
          fontWeight: FontWeight.bold,
        ),
        // 강조
        titleLarge: TextStyle(
          fontSize: 0.054 * w,
          color: kOffBlack,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          fontSize: 0.052 * w,
          color: kOffBlack,
          fontWeight: FontWeight.bold,
        ),
        titleSmall: TextStyle(
          fontSize: 0.05 * w,
          color: kOffBlack,
          fontWeight: FontWeight.bold,
        ),

        /// 기본 대분류
        bodyLarge: TextStyle(
          fontSize: 0.046 * w,
          color: kOffBlack,
          fontWeight: FontWeight.normal,
        ),

        /// 기본 내용
        bodyMedium: TextStyle(
          fontSize: 0.044 * w,
          color: kOffBlack,
          fontWeight: FontWeight.normal,
        ),

        /// 친구 상태 메시지
        bodySmall: TextStyle(
          fontSize: 0.042 * w,
          color: kOffBlack,
          fontWeight: FontWeight.normal,
        ),
        // 라벨
        labelLarge: TextStyle(
          fontSize: 0.034 * w,
          color: kGrey,
          fontWeight: FontWeight.normal,
        ),
        labelMedium: TextStyle(
          fontSize: 0.032 * w,
          color: kGrey,
          fontWeight: FontWeight.normal,
        ),
        labelSmall: TextStyle(
          fontSize: 0.03 * w,
          color: kGrey,
          fontWeight: FontWeight.normal,
        ),
      ),
    );

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeData,
      home: SplashScreen(),
    );
  }
}

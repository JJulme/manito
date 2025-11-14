import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/router.dart';
import 'package:manito/features/error/error_provider.dart';
import 'package:manito/features/theme/theme.dart';
import 'package:manito/features/theme/theme_provider.dart';
import 'package:manito/features/theme/theme_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:manito/features/fcm/firebase_options.dart';

late double width;

void main() async {
  // 웹바인딩 설정
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Hive 설정
  await Hive.initFlutter();
  final db = DatabaseService();
  await db.initTheme();
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
  // 언어 설정
  timeago.setLocaleMessages('ko', timeago.KoMessages());
  // timeago.setLocaleMessages('en_short', timeago.EnMessages());
  // 로컬 노티 설정
  const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('ic_notification');
  const DarwinInitializationSettings darwinInitializationSettings =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitializationSettings,
    iOS: darwinInitializationSettings,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  runApp(
    ProviderScope(
      overrides: [databaseService.overrideWithValue(db)],
      child: EasyLocalization(
        supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
        path: 'assets/translations',
        child: const Manito(),
      ),
    ),
  );
}

class Manito extends ConsumerStatefulWidget {
  const Manito({super.key});

  @override
  ConsumerState<Manito> createState() => _ManitoState();
}

class _ManitoState extends ConsumerState<Manito> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 언어 코드 프로바이더에 저장
    Future.microtask(() {
      if (!mounted) return;
      final lang = context.locale.languageCode;
      ref.read(languageCodeProvider.notifier).state = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    final themeMode = ref.watch(themeProvider);
    // ✅ errorProvider 감시 - 어디서든 에러가 발생하면 여기서 감지
    ref.listen(errorProvider, (previous, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        // 스넥바 표시 후 에러 상태 초기화
        Future.delayed(const Duration(seconds: 2), () {
          ref.read(errorProvider.notifier).clearError();
        });
      }
    });

    return MaterialApp.router(
      routerConfig: ref.read(routerProvider),
      // 다국어 설정
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      // 디버깅 배너 숨기기
      debugShowCheckedModeBanner: false,
      // 테마 설정
      theme: themeLight,
      darkTheme: themeDark,
      themeMode: themeMode,
    );
  }
}

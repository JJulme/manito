import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/router.dart';
import 'package:manito/core/theme/app_theme.dart';
import 'package:manito/core/theme/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:manito/core/fcm/fcm_provider.dart';
import 'package:manito/core/fcm/firebase_options.dart';

import 'dart:convert';
import 'package:timezone/data/latest_all.dart' as tz;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // message.notification이 포함된 FCM 푸시는 Android OS가 백그라운드에서 자동으로 시스템 알림을 표시하므로,
  // 중복 알림(2개) 방지를 위해 로컬 알림은 순수 data-only 메시지일 때만 생성합니다.
  if (message.notification != null) {
    return;
  }

  try {
    final title = message.data['title']?.toString() ?? '마니또 알림';
    final body = message.data['body']?.toString() ?? '';

    if (title.isNotEmpty || body.isNotEmpty) {
      final flutterLocalNotifications = FlutterLocalNotificationsPlugin();
      const androidDetails = AndroidNotificationDetails(
        'default_notification_channel',
        '마니또 알림',
        channelDescription: '마니또 초대, 시작 및 미션 관련 알림을 수신합니다.',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_notification',
        playSound: true,
        enableVibration: true,
      );
      const platformDetails = NotificationDetails(android: androidDetails);
      final notifId = DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;
      await flutterLocalNotifications.show(
        notifId,
        title,
        body,
        platformDetails,
        payload: jsonEncode(message.data),
      );
    }
  } catch (_) {}
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

late double width;

void main() async {
  // 웹바인딩 설정
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Timezone 초기화
  tz.initializeTimeZones();
  // 런처 스플래쉬 화면 설정
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // FCM 설정
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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

  // 안드로이드 노티피케이션 채널 생성 (백그라운드/헤드업 알림 수신 보장)
  const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
    'default_notification_channel',
    '마니또 알림',
    description: '마니또 초대, 시작 및 미션 관련 기본 알림을 수신합니다.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );
  const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
    'manito_general_channel',
    '마니또 알림',
    description: '마니또 초대, 시작 및 미션 관련 알림을 수신합니다.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );
  const AndroidNotificationChannel deadlineChannel = AndroidNotificationChannel(
    'manito_deadline_channel',
    '마니또 마감 알림',
    description: '마니또 게임 마감 전 및 종료 알림을 수신합니다.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );
  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(defaultChannel);
  await androidPlugin?.createNotificationChannel(generalChannel);
  await androidPlugin?.createNotificationChannel(deadlineChannel);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      path: 'assets/translations',
      child: const ProviderScope(
        child: Manito(),
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
    // ✅ 전역 FCM 및 Realtime 알림 리스너 활성화
    ref.watch(fcmListenerProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: ref.read(routerProvider),
      // 다국어 설정
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      // 디버깅 배너 숨기기
      debugShowCheckedModeBanner: false,
      // 테마 설정
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // 전역 키보드 닫기 및 포커스 해제 (GestureDetector Unfocus)
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

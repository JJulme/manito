import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:manito/i18n/strings.g.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'dart:ui';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:manito/features/emoticon/data/models/custom_emoticon_model.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'package:manito/core/util/notification_image_util.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // message.notification이 포함된 경우 Android 시스템이 자체 알림을 띄우므로 중복 방지
  if (message.notification != null) {
    return;
  }

  try {
    final title = message.data['title']?.toString() ?? '마니또 알림';
    final body = message.data['body']?.toString() ?? '';
    final imageUrl = message.data['image_url']?.toString() ?? message.data['sender_profile_url']?.toString();
    final type = message.data['type']?.toString();
    final isChat = type == 'chat_message' || type == 'chatMessage' || (type?.contains('chat') ?? false);

    if (title.isNotEmpty || body.isNotEmpty) {
      final flutterLocalNotifications = FlutterLocalNotificationsPlugin();

      StyleInformation? styleInfo;
      ByteArrayAndroidBitmap? largeIconBitmap;
      Uint8List? imageBytes;

      if (imageUrl != null && imageUrl.trim().isNotEmpty) {
        imageBytes = await NotificationImageUtil.downloadAndProcessProfileImage(imageUrl);
      }

      String? shortcutId;

      if (isChat) {
        final senderName = message.data['sender_name']?.toString() ?? title;
        final senderId = message.data['sender_id']?.toString() ?? 'sender';
        final roomId = message.data['room_id']?.toString();
        shortcutId = roomId ?? senderId;
        final isGroup = title.contains('(');

        const mePerson = Person(
          name: '나',
          key: 'me',
        );

        final senderPerson = Person(
          name: senderName,
          key: senderId,
          icon: imageBytes != null ? ByteArrayAndroidIcon(imageBytes) : null,
          bot: false,
          important: true,
        );

        styleInfo = MessagingStyleInformation(
          mePerson,
          conversationTitle: isGroup ? title : null,
          groupConversation: isGroup,
          messages: [
            Message(
              body,
              DateTime.now(),
              senderPerson,
            ),
          ],
        );
      }

      if (imageBytes != null) {
        largeIconBitmap = ByteArrayAndroidBitmap(imageBytes);
      }

      final androidDetails = AndroidNotificationDetails(
        isChat ? 'chat_notification_channel_v4' : 'default_notification_channel',
        isChat ? '채팅 알림' : '마니또 알림',
        channelDescription: isChat ? '새로운 채팅 메시지 알림을 수신합니다.' : '마니또 초대, 시작 및 미션 관련 알림을 수신합니다.',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_notification',
        largeIcon: largeIconBitmap,
        styleInformation: styleInfo,
        category: isChat ? AndroidNotificationCategory.message : null,
        shortcutId: shortcutId,
        playSound: true,
        enableVibration: true,
      );
      final platformDetails = NotificationDetails(android: androidDetails);
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
  // 안드로이드 몰입 모드 (Immersive Sticky Mode): 시스템 네비게이션 바 & 상태바를 숨겨 전체화면으로 사용
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Timezone 초기화
  tz.initializeTimeZones();
  // Hive 로컬 DB 초기화 (이모티콘 등)
  await Hive.initFlutter();
  Hive.registerAdapter(CustomEmoticonModelAdapter());
  // 런처 스플래쉬 화면 설정
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // FCM 설정
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // Admob 설정
  MobileAds.instance.initialize();
  // .env 변수 가져오기
  await dotenv.load(fileName: '.env');
  // supabase 연결
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  // 언어 설정
  timeago.setLocaleMessages('ko', timeago.KoMessages());

  // 안드로이드 노티피케이션 채널 생성 (백그라운드/헤드업 알림 수신 보장)
  const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
    'default_notification_channel',
    '마니또 알림',
    description: '마니또 초대, 시작 및 미션 관련 기본 알림을 수신합니다.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );
  const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
    'chat_notification_channel_v4',
    '채팅 알림',
    description: '새로운 채팅 메시지 알림을 수신합니다.',
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
  await androidPlugin?.createNotificationChannel(chatChannel);
  await androidPlugin?.createNotificationChannel(generalChannel);
  await androidPlugin?.createNotificationChannel(deadlineChannel);

  // 전역 에러 핸들러 설정
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.e('FlutterError', error: details.exception, stackTrace: details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.e('PlatformError', error: error, stackTrace: stack);
    return true;
  };

  LocaleSettings.useDeviceLocale();

  runApp(
    TranslationProvider(
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
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    final themeMode = ref.watch(themeProvider);
    // ✅ 전역 FCM 및 Realtime 알림 리스너 활성화
    ref.watch(fcmListenerProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: ref.read(routerProvider),
      // 다국어 설정 (slang)
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
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

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../util/app_logger.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService.instance;
});

class AnalyticsService {
  AnalyticsService._internal() {
    _sessionId = _generateSessionId();
    _initPackageInfo();
  }

  static final AnalyticsService instance = AnalyticsService._internal();

  late final String _sessionId;
  String _appVersion = '2.2.1';

  Future<void> _initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
    } catch (e) {
      AppLogger.w('Failed to get package info: $e', tag: 'Analytics');
    }
  }

  String _generateSessionId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = (now % 100000).toString().padLeft(5, '0');
    return 'sess_${now}_$randomSuffix';
  }

  String get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    return 'other';
  }

  /// Log an analytics event to Supabase.
  /// This call is non-blocking and will never throw an uncaught exception.
  Future<void> logEvent(
    String eventName, {
    String? screenName,
    Map<String, dynamic>? properties,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      final payload = {
        'user_id': userId,
        'session_id': _sessionId,
        'event_name': eventName,
        'screen_name': screenName,
        'properties': properties ?? {},
        'app_version': _appVersion,
        'platform': _platform,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      AppLogger.d(
        '📊 [Analytics] $eventName (screen: $screenName, props: $properties)',
        tag: 'Analytics',
      );

      // Non-blocking fire-and-forget insert
      unawaited(
        supabase.from('app_events').insert(payload).catchError((e, stack) {
          AppLogger.w('Failed to insert analytics event: $e', tag: 'Analytics');
        }),
      );
    } catch (e) {
      AppLogger.w('Analytics logging error: $e', tag: 'Analytics');
    }
  }
}

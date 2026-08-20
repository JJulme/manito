import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    filter: _AppLogFilter(),
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Debug log (개발 디버깅용 일반 정보)
  static void d(dynamic message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final prefix = tag != null ? '[$tag] ' : '';
    _logger.d('$prefix$message', error: error, stackTrace: stackTrace);
  }

  /// Info log (주요 상태 변화 및 성공 이벤트)
  static void i(dynamic message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final prefix = tag != null ? '[$tag] ' : '';
    _logger.i('$prefix$message', error: error, stackTrace: stackTrace);
  }

  /// Warning log (경고 및 비치명적 예외)
  static void w(dynamic message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final prefix = tag != null ? '[$tag] ' : '';
    _logger.w('$prefix$message', error: error, stackTrace: stackTrace);
  }

  /// Error log (오류 및 치명적 실패)
  static void e(dynamic message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final prefix = tag != null ? '[$tag] ' : '';
    _logger.e('$prefix$message', error: error, stackTrace: stackTrace);
  }

  /// Verbose/Trace log
  static void t(dynamic message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final prefix = tag != null ? '[$tag] ' : '';
    _logger.t('$prefix$message', error: error, stackTrace: stackTrace);
  }
}

class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kDebugMode || kProfileMode) {
      return true;
    }
    return event.level.value >= Level.warning.value;
  }
}

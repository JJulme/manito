/// 앱 전역 상수이며, 하드코딩을 방지하기 위해 중앙 관리합니다.
class AppConstants {
  AppConstants._(); // 인스턴스 생성 방지

  // 고객지원
  static const String contactEmail = 'manito.ask@gmail.com';

  // 게임 정책
  static const int missionSelectTimeoutSeconds = 60;

  // 앱 버전 fallback
  static const String versionFallback = '0.0.0';
}

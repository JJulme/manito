class DeadlineCalculator {
  // 💡 클래스 이름을 CalculatorService에서 DeadlineCalculator로 변경

  /// 현재 시간을 기준으로 10분 단위로 올림 처리된 시간을 반환
  static DateTime _ceilToNextTenMinutes(DateTime dateTime) {
    final int currentMinute = dateTime.minute;

    // 10분 단위로 올림 처리 (예: 23분 -> 30분, 30분 -> 30분)
    final int targetMinute = (currentMinute / 10).ceil() * 10;

    // 60분을 초과하는 경우 시간(hour)을 올리고 분(minute)은 0으로 설정
    if (targetMinute >= 60) {
      return DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour, // 현재 분은 무시
      ).add(const Duration(hours: 1)); // 60분 이상이면 1시간 추가
    } else {
      // 시간은 유지하고 분만 조정
      return DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
        targetMinute,
      );
    }
  }

  /// 특정 Duration을 현재 시간에 더하고 10분 단위로 올림 처리된 시간을 반환합니다.
  ///
  /// [durationToAdd] : 현재 시간에 더할 Duration 값.
  static DateTime calculateFutureTime(Duration durationToAdd) {
    // 서버와 일관성을 위해 UTC 시간 사용
    final now = DateTime.now().toUtc();
    final DateTime futureTime = now.add(durationToAdd);
    return _ceilToNextTenMinutes(futureTime);
  }
}

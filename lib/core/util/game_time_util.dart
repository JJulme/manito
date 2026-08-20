class GameTimeUtil {
  /// 주어진 기준 시간(기본 now)에서 [minutesToAdd]분을 더한 뒤, 10분 단위로 '무조건 올림(Ceiling)'한 DateTime을 계산합니다.
  /// 예: 현재 12시 3분 + 30분 = 12시 33분 -> 10분 올림 = 12시 40분 00초
  /// 예: 현재 12시 0분 + 30분 = 12시 30분 -> 12시 30분 00초
  /// 예: 현재 12시 3분 + 60분 = 13시 3분 -> 10분 올림 = 13시 10분 00초
  static DateTime calculateCeiledDeadline({DateTime? baseTime, int minutesToAdd = 30}) {
    final start = baseTime ?? DateTime.now();
    final target = start.add(Duration(minutes: minutesToAdd));

    final remainder = target.minute % 10;
    final minutesToAddForCeil = remainder == 0 ? 0 : (10 - remainder);

    final ceiled = target.add(Duration(minutes: minutesToAddForCeil));
    return DateTime(
      ceiled.year,
      ceiled.month,
      ceiled.day,
      ceiled.hour,
      ceiled.minute,
      0, // 0초
      0, // 0밀리초
    );
  }

  /// 10분 단위 포맷 텍스트 (예: 30분, 1시간 40분)
  static String formatDuration(int totalMinutes) {
    if (totalMinutes <= 0) return '0분';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '$hours시간 $minutes분';
    } else if (hours > 0) {
      return '$hours시간';
    } else {
      return '$minutes분';
    }
  }

  /// 한국어 날짜 및 시간 포맷 (예: 8월 11일 (화) 오후 09:30)
  static String formatKoreanDateTime(DateTime dt) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekdayStr = weekdays[dt.weekday - 1];
    final isPm = dt.hour >= 12;
    final displayHour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = isPm ? '오후' : '오전';
    final minuteStr = dt.minute.toString().padLeft(2, '0');

    return '${dt.month}월 ${dt.day}일 ($weekdayStr) $period ${displayHour.toString().padLeft(2, '0')}:$minuteStr';
  }

  /// 대기실 잔여 시간 계산 (10분 기준)
  static int getRemainingWaitingMinutes(DateTime createdAt) {
    final elapsed = DateTime.now().difference(createdAt).inMinutes;
    return (10 - elapsed).clamp(0, 10);
  }
}

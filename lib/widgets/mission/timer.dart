import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

/// TimerWidget 클래스: 카운트다운을 표시하는 위젯
class TimerWidget extends StatelessWidget {
  final DateTime targetDateTime; // 타이머 종료 시간
  final double fontSize; // 글자 크기
  final Color color; // 글자 색상
  final Future<void> Function()? onTimerComplete;

  // 생성자에서 타이머 시간, 글자 크기, 글자 색상 설정
  const TimerWidget({
    super.key,
    required this.targetDateTime,
    required this.fontSize,
    this.color = Colors.black,
    this.onTimerComplete,
  });

  @override
  Widget build(BuildContext context) {
    // 고유한 TimerController 생성 및 관리
    // 각 TimerWidget마다 별도로 TimerController가 생성되며, 타이머가 시작됩니다.
    final TimerController controller = TimerController(
      targetDateTime,
      onTimerComplete: onTimerComplete,
    );

    return Obx(() {
      // 남은 시간 포맷팅
      var textList = controller.formatRemainingTime(
        controller.remainingTime.value,
      );
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // '일'과 시간, 분을 표시하는 텍스트 위젯들
          Text(
            textList[0],
            style: TextStyle(
              fontFamily: 'Digital',
              fontSize: fontSize,
              color: color,
            ),
          ),
          if (textList.length > 1) // 일 수가 0보다 클 때만 "일" 표시
            Text(
              "timer.day",
              style: TextStyle(fontSize: fontSize * 0.83, color: color),
            ).tr(),
          if (textList.length > 1) // 일 수가 0보다 클 때만 시간 표시
            Text(
              textList[1],
              style: TextStyle(
                fontFamily: 'Digital',
                fontSize: fontSize,
                color: color,
              ),
            ),
          // Text(
          //   ' 남음',
          //   style: TextStyle(
          //     fontFamily: 'Digital',
          //     fontSize: fontSize * 0.83,
          //     color: color,
          //   ),
          // ),
        ],
      );
    });
  }
}

// TimerController 클래스: 카운트다운 로직을 처리하는 컨트롤러
class TimerController extends GetxController {
  final DateTime targetDateTime; // 타이머 종료 시간
  final Future<void> Function()? onTimerComplete; // 타이머 종료하면 실행하는 함수

  // 생성자에서 타이머 종료 시간을 받아 초기화하고 타이머 시작
  TimerController(this.targetDateTime, {this.onTimerComplete}) {
    startCountdown(); // 타이머 시작
  }

  Rx<Duration> remainingTime = Duration.zero.obs; // 남은 시간
  Timer? _timer; // 타이머 객체
  RxBool isCountdownRunning = false.obs; // 타이머 상태

  // 타이머 시작 함수
  void startCountdown() {
    // 이미 타이머가 실행 중이라면 다시 시작하지 않음
    if (isCountdownRunning.value) return;

    isCountdownRunning.value = true; // 타이머 실행 중으로 설정
    _updateRemainingTime(); // 남은 시간 초기화

    // 1초마다 타이머 업데이트
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final now = DateTime.now().toUtc().add(const Duration(hours: 0));
      if (now.isAfter(targetDateTime)) {
        // 타이머 종료 시간 지나면 타이머 멈추고 종료
        timer.cancel();
        isCountdownRunning.value = false;
        remainingTime.value = Duration.zero;
        // 타이머 종료되고 실행되는 함수
        await onTimerComplete?.call();
      } else {
        _updateRemainingTime(); // 남은 시간 갱신
      }
    });
  }

  // 남은 시간 계산 후 업데이트
  void _updateRemainingTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 0));
    final difference = targetDateTime.difference(now);
    remainingTime.value =
        difference > Duration.zero ? difference : Duration.zero;
  }

  // 남은 시간을 "일 시:분" 형식으로 반환
  List<String> formatRemainingTime(Duration duration) {
    int days = duration.inDays; // 남은 일
    String hours = (duration.inHours % 24).toString().padLeft(2, '0'); // 남은 시간
    String minutes = (duration.inMinutes % 60).toString().padLeft(
      2,
      '0',
    ); // 남은 분
    String seconds = (duration.inSeconds % 60).toString().padLeft(
      2,
      '0',
    ); // 남은 초

    if (days > 0) {
      return ['$days', '$hours:$minutes:$seconds']; // "일 시:분" 형식
    } else {
      return ['$hours:$minutes:$seconds']; // "시:분" 형식
    }
  }

  // 타이머가 종료되면 타이머를 정리
  @override
  void onClose() {
    _timer?.cancel(); // 타이머 정리
    super.onClose();
  }
}

import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// TimerState 클래스: 타이머의 상태를 나타내는 클래스
class TimerState {
  final Duration remainingTime;
  final bool isCountdownRunning;
  final bool isCompleted;

  const TimerState({
    required this.remainingTime,
    required this.isCountdownRunning,
    required this.isCompleted,
  });

  TimerState copyWith({
    Duration? remainingTime,
    bool? isCountdownRunning,
    bool? isCompleted,
  }) {
    return TimerState(
      remainingTime: remainingTime ?? this.remainingTime,
      isCountdownRunning: isCountdownRunning ?? this.isCountdownRunning,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// TimerNotifier 클래스: 타이머 상태를 관리하는 StateNotifier
class TimerNotifier extends StateNotifier<TimerState> {
  final DateTime targetDateTime;
  final Future<void> Function()? onTimerComplete;
  Timer? _timer;
  bool _callbackExecuted = false; // 콜백 실행 여부를 추적하는 단순한 플래그

  TimerNotifier({required this.targetDateTime, this.onTimerComplete})
    : super(
        const TimerState(
          remainingTime: Duration.zero,
          isCountdownRunning: false,
          isCompleted: false,
        ),
      ) {
    startCountdown();
  }

  // 타이머 시작 함수
  void startCountdown() {
    if (state.isCountdownRunning || _callbackExecuted) return;

    state = state.copyWith(isCountdownRunning: true);
    _updateRemainingTime();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // 콜백이 이미 실행되었다면 타이머 중단
      if (_callbackExecuted) {
        timer.cancel();
        return;
      }

      final now = DateTime.now().toUtc();
      if (now.isAfter(targetDateTime)) {
        // 먼저 콜백 실행 플래그를 true로 설정 (가장 우선)
        _callbackExecuted = true;

        // 타이머 정지
        timer.cancel();
        _timer = null;

        // 상태 업데이트
        state = state.copyWith(
          isCountdownRunning: false,
          remainingTime: Duration.zero,
          isCompleted: true,
        );

        // 콜백 실행 (비동기이지만 플래그로 보호됨)
        _executeCallback();
      } else {
        _updateRemainingTime();
      }
    });
  }

  // 콜백 실행 함수 분리
  void _executeCallback() async {
    if (onTimerComplete != null) {
      try {
        await onTimerComplete!();
      } catch (e) {
        // 에러 처리 (선택사항)
        debugPrint('Timer callback error: $e');
      }
    }
  }

  // 남은 시간 계산 후 업데이트
  void _updateRemainingTime() {
    if (_callbackExecuted) return;

    final now = DateTime.now().toUtc();
    final difference = targetDateTime.difference(now);
    final remaining = difference > Duration.zero ? difference : Duration.zero;

    if (!_callbackExecuted) {
      // 한 번 더 체크
      state = state.copyWith(remainingTime: remaining);
    }
  }

  // 남은 시간을 "일 시:분:초" 형식으로 반환
  List<String> formatRemainingTime(Duration duration) {
    int days = duration.inDays;
    String hours = (duration.inHours % 24).toString().padLeft(2, '0');
    String minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    if (days > 0) {
      return ['$days', '$hours:$minutes:$seconds'];
    } else {
      return ['$hours:$minutes:$seconds'];
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

/// 새로운 코드
// class TimerNotifier extends Notifier<TimerState> {
//   late final DateTime _targetDateTime;
//   Future<void> Function()? _onTimerComplete;
//   Timer? _timer;
//   bool _callbackExecuted = false;

//   @override
//   TimerState build() {
//     return const TimerState(
//       remainingTime: Duration.zero,
//       isCountdownRunning: false,
//       isCompleted: false,
//     );
//   }

//   void initialize(DateTime targetDateTime, {Future<void> Function()? onTimerComplete}) {
//     _targetDateTime = targetDateTime;
//     _onTimerComplete = onTimerComplete;

//   }
// }

/// TimerWidget 클래스: 카운트다운을 표시하는 위젯
class TimerWidget extends ConsumerStatefulWidget {
  final DateTime targetDateTime;
  final double fontSize;
  final Future<void> Function()? onTimerComplete;

  const TimerWidget({
    super.key,
    required this.targetDateTime,
    required this.fontSize,
    this.onTimerComplete,
  });

  @override
  ConsumerState<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends ConsumerState<TimerWidget> {
  late final StateNotifierProvider<TimerNotifier, TimerState> _timerProvider;

  @override
  void initState() {
    super.initState();
    // initState에서 한 번만 Provider 생성
    _timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
      final notifier = TimerNotifier(
        targetDateTime: widget.targetDateTime,
        onTimerComplete: widget.onTimerComplete,
      );

      ref.onDispose(() {
        notifier.dispose();
      });

      return notifier;
    });
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(_timerProvider);
    final timerNotifier = ref.read(_timerProvider.notifier);

    // 남은 시간 포맷팅
    var textList = timerNotifier.formatRemainingTime(timerState.remainingTime);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // '일'과 시간, 분을 표시하는 텍스트 위젯들
        Text(
          textList[0],
          style: TextStyle(fontFamily: 'Digital', fontSize: widget.fontSize),
        ),
        if (textList.length > 1) // 일 수가 0보다 클 때만 "일" 표시
          Text(
            "timer.day",
            style: TextStyle(fontSize: widget.fontSize * 0.83),
          ).tr(),
        if (textList.length > 1) // 일 수가 0보다 클 때만 시간 표시
          Text(
            textList[1],
            style: TextStyle(fontFamily: 'Digital', fontSize: widget.fontSize),
          ),
      ],
    );
  }
}

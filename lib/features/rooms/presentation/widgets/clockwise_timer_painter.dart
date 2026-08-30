import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 12시 방향에서 시작하여 시계방향으로 줄어드는 원형 타이머 페인터
class ClockwiseTimerPainter extends CustomPainter {
  final double progress; // 1.0 (가득 참) -> 0.0 (비어있음)
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  ClockwiseTimerPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. 전체 트랙 원 그리기
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // 2. 12시 방향부터 시계방향으로 줄어드는 호(Arc) 그리기
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 12시 방향(-pi/2)에서 경과된 각도만큼 이동한 위치에서 시작하여 남은 각도만큼 시계방향으로 그림
    const startOffset = -math.pi / 2;
    final elapsedAngle = (1.0 - progress) * 2 * math.pi;
    final startAngle = startOffset + elapsedAngle;
    final sweepAngle = progress * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ClockwiseTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}

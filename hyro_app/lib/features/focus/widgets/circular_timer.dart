import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/format_time.dart';

/// The circular Pomodoro timer widget with animated glow.
class CircularTimer extends StatelessWidget {
  final int remainingSeconds;
  final double progress;
  final String label;
  final double size;

  const CircularTimer({
    super.key,
    required this.remainingSeconds,
    required this.progress,
    this.label = 'TIEMPO HASTA EL DESCANSO',
    this.size = 300,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Background circle ──
          CustomPaint(
            size: Size(size, size),
            painter: _TimerRingPainter(
              progress: progress,
              progressColor: AppColors.timerColor,
              trackColor: AppColors.surfaceLight,
              glowColor: AppColors.timerGlow,
              strokeWidth: 6,
            ),
          ),
          // ── Time display ──
          Padding(
            padding: EdgeInsets.all(size * 0.15),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    FormatTime.mmss(remainingSeconds),
                    style: AppTypography.timerDisplay,
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: AppTypography.timerLabel),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;
  final Color glowColor;
  final double strokeWidth;

  _TimerRingPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.glowColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    // Track
    final trackPaint =
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint =
          Paint()
            ..color = progressColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );

      // Glow effect
      final glowPaint =
          Paint()
            ..color = glowColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth + 12
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

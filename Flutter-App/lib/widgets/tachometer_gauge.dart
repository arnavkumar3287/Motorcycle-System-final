import 'dart:math' as math;
import 'package:flutter/material.dart';

class TachometerGauge extends StatelessWidget {
  final double currentRpm;
  final double optimalRpm;
  final int currentGear;
  final double maxRpm;

  const TachometerGauge({
    super.key,
    required this.currentRpm,
    required this.optimalRpm,
    required this.currentGear,
    this.maxRpm = 10000.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(280, 280),
            painter: _TachometerPainter(
              rpm: currentRpm,
              optimalRpm: optimalRpm,
              maxRpm: maxRpm,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'GEAR $currentGear',
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currentRpm.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
              const Text(
                'RPM',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2330),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  'TARGET: ${optimalRpm.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TachometerPainter extends CustomPainter {
  final double rpm;
  final double optimalRpm;
  final double maxRpm;

  _TachometerPainter({
    required this.rpm,
    required this.optimalRpm,
    required this.maxRpm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    const startAngle = 135 * (math.pi / 180);
    const sweepAngle = 270 * (math.pi / 180);

    // Track Background Arc
    final bgPaint = Paint()
      ..color = const Color(0xFF1B202D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Redline Arc (> 7,500 RPM)
    final redlineFraction = (maxRpm - 7500.0) / maxRpm;
    final redlineStartAngle = startAngle + (sweepAngle * (7500.0 / maxRpm));
    final redlineSweep = sweepAngle * redlineFraction;

    final redlinePaint = Paint()
      ..color = const Color(0x66FF3333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      redlineStartAngle,
      redlineSweep,
      false,
      redlinePaint,
    );

    // Active RPM Arc
    final currentFraction = (rpm / maxRpm).clamp(0.0, 1.0);
    final currentSweep = sweepAngle * currentFraction;

    final isRedline = rpm >= 7500.0;
    final activeColor = isRedline ? const Color(0xFFFF3333) : const Color(0xFF00E5FF);

    final activePaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF00FF66), activeColor],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      currentSweep,
      false,
      activePaint,
    );

    // Target Shift Indicator Notch
    final targetFraction = (optimalRpm / maxRpm).clamp(0.0, 1.0);
    final targetAngle = startAngle + (sweepAngle * targetFraction);
    final targetX = center.dx + (radius) * math.cos(targetAngle);
    final targetY = center.dy + (radius) * math.sin(targetAngle);

    final targetPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(targetX, targetY), 6, targetPaint);
  }

  @override
  bool shouldRepaint(covariant _TachometerPainter oldDelegate) {
    return oldDelegate.rpm != rpm || oldDelegate.optimalRpm != optimalRpm;
  }
}

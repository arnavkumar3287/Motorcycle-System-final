import 'dart:math' as math;
import 'package:flutter/material.dart';

class LeanAngleWidget extends StatelessWidget {
  final double leanAngleDeg;
  final bool isColdTireHazard;

  const LeanAngleWidget({
    super.key,
    required this.leanAngleDeg,
    this.isColdTireHazard = false,
  });

  @override
  Widget build(BuildContext context) {
    final absLean = leanAngleDeg.abs();
    final direction = leanAngleDeg < 0 ? 'LEFT' : (leanAngleDeg > 0 ? 'RIGHT' : 'CENTER');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14171F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isColdTireHazard ? const Color(0xFFFF3333) : const Color(0xFF222938),
          width: isColdTireHazard ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LEAN ANGLE (IMU)',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              if (isColdTireHazard)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x33FF3333),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF3333)),
                  ),
                  child: const Text(
                    'COLD TIRE HAZARD',
                    style: TextStyle(
                      color: Color(0xFFFF3333),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            width: double.infinity,
            child: CustomPaint(
              painter: _LeanAnglePainter(leanAngleDeg: leanAngleDeg, isHazard: isColdTireHazard),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${absLean.toStringAsFixed(1)}° ',
                style: TextStyle(
                  color: isColdTireHazard ? const Color(0xFFFF3333) : Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                direction,
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeanAnglePainter extends CustomPainter {
  final double leanAngleDeg;
  final bool isHazard;

  _LeanAnglePainter({required this.leanAngleDeg, required this.isHazard});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);
    final width = size.width * 0.8;

    // Horizon line
    final horizonPaint = Paint()
      ..color = const Color(0xFF2A3245)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(center.dx - width / 2, center.dy), Offset(center.dx + width / 2, center.dy), horizonPaint);

    // Tilted bike indicator line
    final rad = leanAngleDeg * (math.pi / 180.0);
    final indicatorPaint = Paint()
      ..color = isHazard ? const Color(0xFFFF3333) : const Color(0xFF00E5FF)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final dx = (width / 2.5) * math.cos(rad);
    final dy = (width / 2.5) * math.sin(rad);

    canvas.drawLine(Offset(center.dx - dx, center.dy - dy), Offset(center.dx + dx, center.dy + dy), indicatorPaint);

    // Center pivot point
    final pivotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 4, pivotPaint);
  }

  @override
  bool shouldRepaint(covariant _LeanAnglePainter oldDelegate) {
    return oldDelegate.leanAngleDeg != leanAngleDeg || oldDelegate.isHazard != isHazard;
  }
}

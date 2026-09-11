import 'package:flutter/material.dart';

class TpmsTireCard extends StatelessWidget {
  final String title;
  final double pressurePsi;
  final double temperatureC;

  const TpmsTireCard({
    super.key,
    required this.title,
    required this.pressurePsi,
    required this.temperatureC,
  });

  @override
  Widget build(BuildContext context) {
    final isCold = temperatureC < 25.0;
    final isLow = pressurePsi < 26.0;

    final tempColor = isCold ? const Color(0xFF3399FF) : (temperatureC > 45.0 ? const Color(0xFFFF9900) : const Color(0xFF00FF66));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14171F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLow ? const Color(0xFFFF3333) : const Color(0xFF222938),
          width: isLow ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              if (isCold)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x333399FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF3399FF)),
                  ),
                  child: const Text(
                    'COLD TIRE',
                    style: TextStyle(color: Color(0xFF3399FF), fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        pressurePsi.toStringAsFixed(1),
                        style: TextStyle(
                          color: isLow ? const Color(0xFFFF3333) : Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('PSI', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Text('PRESSURE', style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        temperatureC.toStringAsFixed(1),
                        style: TextStyle(
                          color: tempColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('°C', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Text('TEMPERATURE', style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

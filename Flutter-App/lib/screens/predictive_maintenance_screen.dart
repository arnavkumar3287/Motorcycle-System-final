import 'package:flutter/material.dart';
import '../services/telemetry_simulator_service.dart';
import '../services/predictive_maintenance_service.dart';
import '../models/telemetry_frame.dart';

class PredictiveMaintenanceScreen extends StatelessWidget {
  final TelemetrySimulatorService telemetryService;

  const PredictiveMaintenanceScreen({super.key, required this.telemetryService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TelemetryFrame>(
      stream: telemetryService.frameStream,
      builder: (context, snapshot) {
        final summary = telemetryService.getRideSummary();
        final items = PredictiveMaintenanceService.evaluateCondition(
          totalDistanceKm: summary.distanceKm,
          mechanicalStressIndex: summary.mechanicalStressIndex,
          luggingEvents: summary.luggingEventsCount,
          overRevEvents: summary.overRevEventsCount,
          aggressiveCornerExits: summary.aggressiveCornerExitCount,
        );

        return Scaffold(
          backgroundColor: const Color(0xFF0B0E14),
          appBar: AppBar(
            backgroundColor: const Color(0xFF14171F),
            elevation: 0,
            title: const Text(
              'PREDICTIVE WEAR & TEAR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Wear Tracking Philosophy Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14171F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF222938)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0x3300E5FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.build_circle_rounded, color: Color(0xFF00E5FF), size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CONDITION-BASED MAINTENANCE',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Replaces fixed-distance service schedules with live thermal & mechanical stress telemetry.',
                              style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Mechanical Stress Index
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14171F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF222938)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MECHANICAL STRESS FACTOR', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Torque & Thermal Ingestion', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      Text(
                        '${summary.mechanicalStressIndex}',
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'COMPONENT HEALTH & WEAR INDICATORS',
                  style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 12),

                // 3. Component list
                for (final item in items) ...[
                  _buildComponentCard(item),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComponentCard(MaintenanceItem item) {
    Color barColor;
    if (item.currentHealthPct > 50) {
      barColor = const Color(0xFF00FF66);
    } else if (item.currentHealthPct > item.thresholdWarningPct) {
      barColor = const Color(0xFFFFB300);
    } else {
      barColor = const Color(0xFFFF3333);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14171F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.isWarning ? const Color(0xFFFF3333) : const Color(0xFF222938)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.name,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                '${item.currentHealthPct}% Life',
                style: TextStyle(color: barColor, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: item.currentHealthPct / 100.0,
              minHeight: 8,
              backgroundColor: const Color(0xFF1E2330),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.statusDescription,
                style: TextStyle(color: item.isWarning ? const Color(0xFFFF3333) : Colors.white70, fontSize: 12),
              ),
              Text(
                item.recommendation,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

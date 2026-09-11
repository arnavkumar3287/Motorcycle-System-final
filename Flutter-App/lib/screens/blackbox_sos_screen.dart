import 'package:flutter/material.dart';
import '../services/telemetry_simulator_service.dart';

class BlackboxSosScreen extends StatelessWidget {
  final TelemetrySimulatorService telemetryService;

  const BlackboxSosScreen({super.key, required this.telemetryService});

  @override
  Widget build(BuildContext context) {
    final blackbox = telemetryService.blackboxService;
    final incidents = blackbox.lockedIncidents;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14171F),
        elevation: 0,
        title: const Text(
          'AUTOMATED SOS & BLACKBOX',
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
            // 1. Blackbox Ring Buffer Monitor Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF14171F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: blackbox.isIncidentLocked ? const Color(0xFFFF3333) : const Color(0xFF00FF66),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    blackbox.isIncidentLocked ? Icons.lock_rounded : Icons.shield_rounded,
                    color: blackbox.isIncidentLocked ? const Color(0xFFFF3333) : const Color(0xFF00FF66),
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          blackbox.isIncidentLocked ? 'CRASH LOCKED • SOS ACTIVE' : '60-SEC RING BUFFER ACTIVE',
                          style: TextStyle(
                            color: blackbox.isIncidentLocked ? const Color(0xFFFF3333) : const Color(0xFF00FF66),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          blackbox.isIncidentLocked
                              ? 'Prior 60 seconds of telemetry locked in local non-volatile storage.'
                              : 'Continuously buffering rolling 600 frames (10Hz). Triggers at >4.5G spike or >80° lean.',
                          style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'RECORDED CRASH / LOCKBOX INCIDENTS',
              style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),

            if (incidents.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF14171F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF222938)),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: Color(0xFF00FF66), size: 48),
                      SizedBox(height: 12),
                      Text(
                        'No Critical Incidents Detected',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'System actively monitoring IMU G-forces & lean angles.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final incident in incidents) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14171F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFF3333)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '🚨 SEVERE IMPACT DETECTED',
                            style: TextStyle(color: Color(0xFFFF3333), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            incident.timestamp.toString().substring(11, 19),
                            style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildDetail('Peak G-Force', '${incident.peakGForce.toStringAsFixed(2)} G')),
                          Expanded(child: _buildDetail('Impact Lean', '${incident.peakLeanAngle.toStringAsFixed(1)}°')),
                          Expanded(child: _buildDetail('Speed', '${incident.speedKmh.toStringAsFixed(0)} km/h')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2330),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Color(0xFF00E5FF), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'GPS Coordinates: ${incident.latitude.toStringAsFixed(4)}, ${incident.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

import '../models/telemetry_frame.dart';

class HazardDetector {
  static const double coldTireTempThresholdC = 25.0;
  static const double extremeLeanAngleDeg = 24.0;
  static const double lowTirePressurePsi = 26.0;
  static const double highTirePressurePsi = 38.0;
  static const double panicBrakingLongG = -0.65;
  static const double crashSpikeGForce = 4.5;
  static const double crashLeanAngleDeg = 80.0;

  static HazardAssessment assess({
    required double leanAngleDeg,
    required double frontTireTempC,
    required double frontTirePressPsi,
    required double rearTireTempC,
    required double rearTirePressPsi,
    required double longitudinalAccelG,
    required double lateralAccelG,
    required double engineRpm,
    required double engineLoadPct,
    required int currentGear,
  }) {
    // 1. Crash Detection: Extreme G-force spike or 80-90 degree lean angle
    final totalG = (longitudinalAccelG.abs() + lateralAccelG.abs());
    if (totalG > crashSpikeGForce || leanAngleDeg.abs() >= crashLeanAngleDeg) {
      return const HazardAssessment(
        type: HazardType.crashDetected,
        severity: 3,
        message: '🚨 CRASH DETECTED! SOS Blackbox Locked',
      );
    }

    // 2. Cold Tires + Aggressive Lean: High risk of low-side slide
    final minTemp = frontTireTempC < rearTireTempC ? frontTireTempC : rearTireTempC;
    if (leanAngleDeg.abs() > extremeLeanAngleDeg && minTemp < coldTireTempThresholdC) {
      return HazardAssessment(
        type: HazardType.coldTireLean,
        severity: 2,
        message: '⚠️ COLD TIRES (${minTemp.toStringAsFixed(1)}°C) + LEAN (${leanAngleDeg.abs().toStringAsFixed(1)}°)! Risk of Traction Loss',
      );
    }

    // 3. Engine Lugging under strain
    if (engineRpm < 2500 && engineLoadPct > 50.0 && currentGear > 1) {
      return const HazardAssessment(
        type: HazardType.engineLugging,
        severity: 1,
        message: '⚠️ ENGINE LUGGING! Downshift immediately',
      );
    }

    // 4. Tire Pressure Hazard
    if (frontTirePressPsi < lowTirePressurePsi || rearTirePressPsi < lowTirePressurePsi) {
      return const HazardAssessment(
        type: HazardType.tireUnderinflated,
        severity: 1,
        message: '⚠️ LOW TIRE PRESSURE DETECTED! Check TPMS',
      );
    }

    return const HazardAssessment(
      type: HazardType.none,
      severity: 0,
      message: '',
    );
  }
}

class HazardAssessment {
  final HazardType type;
  final int severity; // 0: None, 1: Advisory, 2: Warning, 3: Critical
  final String message;

  const HazardAssessment({
    required this.type,
    required this.severity,
    required this.message,
  });
}

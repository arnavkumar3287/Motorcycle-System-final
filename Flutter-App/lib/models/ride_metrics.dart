import 'telemetry_frame.dart';

enum UbiRiskTier { safe, moderate, highRisk }

class RideMetrics {
  final int totalFrames;
  final Duration duration;
  final double distanceKm;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final double avgRpm;
  final double maxRpm;
  final double maxLeanAngleDeg;

  // Gamified Ride Score (0-100)
  final int overallRideScore;
  final int shiftEfficiencyScore;
  final int smoothnessScore;
  final int safetyScore;

  // Fuel & Transmission Degrading Habits
  final int luggingEventsCount;
  final double luggingDurationSec;
  final int overRevEventsCount;
  final double overRevDurationSec;
  final int aggressiveCornerExitCount;
  final int coldTireHazardCount;
  final int highRiskOvertakesCount;

  // UBI Insurance Rating
  final UbiRiskTier riskTier;
  final double projectedDiscountPct; // e.g. 15.0% discount or -10.0% surcharge

  // Predictive Wear and Tear Indicators (0 - 100% remaining)
  final double engineOilLifePct;
  final double brakePadLifePct;
  final double chainLifePct;
  final double mechanicalStressIndex;

  const RideMetrics({
    required this.totalFrames,
    required this.duration,
    required this.distanceKm,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.avgRpm,
    required this.maxRpm,
    required this.maxLeanAngleDeg,
    required this.overallRideScore,
    required this.shiftEfficiencyScore,
    required this.smoothnessScore,
    required this.safetyScore,
    required this.luggingEventsCount,
    required this.luggingDurationSec,
    required this.overRevEventsCount,
    required this.overRevDurationSec,
    required this.aggressiveCornerExitCount,
    required this.coldTireHazardCount,
    required this.highRiskOvertakesCount,
    required this.riskTier,
    required this.projectedDiscountPct,
    required this.engineOilLifePct,
    required this.brakePadLifePct,
    required this.chainLifePct,
    required this.mechanicalStressIndex,
  });

  factory RideMetrics.fromFrames(List<TelemetryFrame> frames) {
    if (frames.isEmpty) {
      return const RideMetrics(
        totalFrames: 0,
        duration: Duration.zero,
        distanceKm: 0.0,
        avgSpeedKmh: 0.0,
        maxSpeedKmh: 0.0,
        avgRpm: 0.0,
        maxRpm: 0.0,
        maxLeanAngleDeg: 0.0,
        overallRideScore: 100,
        shiftEfficiencyScore: 100,
        smoothnessScore: 100,
        safetyScore: 100,
        luggingEventsCount: 0,
        luggingDurationSec: 0.0,
        overRevEventsCount: 0,
        overRevDurationSec: 0.0,
        aggressiveCornerExitCount: 0,
        coldTireHazardCount: 0,
        highRiskOvertakesCount: 0,
        riskTier: UbiRiskTier.safe,
        projectedDiscountPct: 20.0,
        engineOilLifePct: 100.0,
        brakePadLifePct: 100.0,
        chainLifePct: 100.0,
        mechanicalStressIndex: 0.0,
      );
    }

    double speedSum = 0;
    double maxSpeed = 0;
    double rpmSum = 0;
    double maxRpm = 0;
    double maxLean = 0;
    int luggingFrames = 0;
    int overRevFrames = 0;
    int coldTireHazardFrames = 0;
    int aggressiveRollOnCount = 0;
    int overtakeCount = 0;
    double totalStress = 0;

    for (int i = 0; i < frames.length; i++) {
      final f = frames[i];
      speedSum += f.vehicleSpeedKmh;
      if (f.vehicleSpeedKmh > maxSpeed) maxSpeed = f.vehicleSpeedKmh;

      rpmSum += f.engineRpm;
      if (f.engineRpm > maxRpm) maxRpm = f.engineRpm;

      if (f.leanAngleDeg.abs() > maxLean) maxLean = f.leanAngleDeg.abs();

      if (f.isLugging) luggingFrames++;
      if (f.isOverRevving) overRevFrames++;
      if (f.hazardType == HazardType.coldTireLean) coldTireHazardFrames++;

      if (f.leanAngleDeg.abs() > 15 && f.throttlePosPct > 60) {
        aggressiveRollOnCount++;
      }

      if (f.longitudinalAccelG > 0.4 && f.vehicleSpeedKmh > 70) {
        overtakeCount++;
      }

      totalStress += (f.engineLoadPct * f.engineRpm) / 10000.0;
    }

    final durationSec = frames.length * 0.1; // 100ms intervals
    final avgSpeed = speedSum / frames.length;
    final avgRpm = rpmSum / frames.length;
    final distance = (avgSpeed * (durationSec / 3600.0));

    // Calculate component scores
    final luggingPenalty = (luggingFrames / frames.length) * 120.0;
    final overRevPenalty = (overRevFrames / frames.length) * 150.0;
    final shiftScore = (100 - (luggingPenalty + overRevPenalty)).clamp(10, 100).toInt();

    final hazardPenalty = (coldTireHazardFrames / frames.length) * 300.0;
    final safetyScore = (100 - (hazardPenalty + (overtakeCount * 2.5))).clamp(10, 100).toInt();

    final smoothnessScore = (100 - (aggressiveRollOnCount * 1.5)).clamp(15, 100).toInt();

    final overallRideScore = ((shiftScore * 0.35) + (safetyScore * 0.40) + (smoothnessScore * 0.25)).round().clamp(10, 100);

    // UBI Tier calculation
    UbiRiskTier tier;
    double discountPct;
    if (overallRideScore >= 80) {
      tier = UbiRiskTier.safe;
      discountPct = 15.0 + ((overallRideScore - 80) * 0.5); // 15% to 25% discount
    } else if (overallRideScore >= 60) {
      tier = UbiRiskTier.moderate;
      discountPct = 5.0 + ((overallRideScore - 60) * 0.4); // 5% to 13% discount
    } else {
      tier = UbiRiskTier.highRisk;
      discountPct = -10.0 + ((overallRideScore - 40) * 0.5); // Surcharge up to 10%
    }

    // Predictive wear and tear
    final avgStress = totalStress / frames.length;
    final oilLife = (98.5 - (avgStress * 0.05)).clamp(10.0, 100.0);
    final brakeLife = (96.0 - (aggressiveRollOnCount * 0.04)).clamp(15.0, 100.0);
    final chainLife = (97.0 - (overtakeCount * 0.03)).clamp(12.0, 100.0);

    return RideMetrics(
      totalFrames: frames.length,
      duration: Duration(seconds: durationSec.round()),
      distanceKm: double.parse(distance.toStringAsFixed(2)),
      avgSpeedKmh: double.parse(avgSpeed.toStringAsFixed(1)),
      maxSpeedKmh: double.parse(maxSpeed.toStringAsFixed(1)),
      avgRpm: double.parse(avgRpm.toStringAsFixed(0)),
      maxRpm: double.parse(maxRpm.toStringAsFixed(0)),
      maxLeanAngleDeg: double.parse(maxLean.toStringAsFixed(1)),
      overallRideScore: overallRideScore,
      shiftEfficiencyScore: shiftScore,
      smoothnessScore: smoothnessScore,
      safetyScore: safetyScore,
      luggingEventsCount: (luggingFrames / 10).ceil(),
      luggingDurationSec: double.parse((luggingFrames * 0.1).toStringAsFixed(1)),
      overRevEventsCount: (overRevFrames / 10).ceil(),
      overRevDurationSec: double.parse((overRevFrames * 0.1).toStringAsFixed(1)),
      aggressiveCornerExitCount: aggressiveRollOnCount,
      coldTireHazardCount: (coldTireHazardFrames / 10).ceil(),
      highRiskOvertakesCount: overtakeCount,
      riskTier: tier,
      projectedDiscountPct: double.parse(discountPct.toStringAsFixed(1)),
      engineOilLifePct: double.parse(oilLife.toStringAsFixed(1)),
      brakePadLifePct: double.parse(brakeLife.toStringAsFixed(1)),
      chainLifePct: double.parse(chainLife.toStringAsFixed(1)),
      mechanicalStressIndex: double.parse(avgStress.toStringAsFixed(1)),
    );
  }
}

class CrashEventBlackbox {
  final DateTime timestamp;
  final double peakGForce;
  final double peakLeanAngle;
  final double speedKmh;
  final double latitude;
  final double longitude;
  final List<TelemetryFrame> preCrashTelemetry;

  const CrashEventBlackbox({
    required this.timestamp,
    required this.peakGForce,
    required this.peakLeanAngle,
    required this.speedKmh,
    required this.latitude,
    required this.longitude,
    required this.preCrashTelemetry,
  });
}

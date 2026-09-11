class ShiftIntelligence {
  static const double hysteresisBufferRpm = 250.0;
  static const double luggingRpmLimit = 2500.0;
  static const double luggingLoadThreshold = 50.0;

  // Calibrated baseline shift RPM per gear for Triumph Scrambler 400x
  static const Map<int, double> baselineShiftRpm = {
    1: 4400.0,
    2: 5400.0,
    3: 6000.0,
    4: 6400.0,
    5: 6800.0,
    6: 7200.0,
  };

  /// Calculates dynamic optimal shift RPM using regression logic
  /// (mapping engine load %, throttle %, road incline deg, and gear).
  static double predictOptimalShiftRpm({
    required double engineLoadPct,
    required double throttlePosPct,
    required double roadInclineDeg,
    required int currentGear,
  }) {
    final base = baselineShiftRpm[currentGear] ?? 5500.0;

    // Under steep incline or heavy acceleration, shift RPM shifts higher to keep engine in powerband
    final inclineOffset = roadInclineDeg * 60.0;
    final loadOffset = (engineLoadPct - 30.0).clamp(-20.0, 70.0) * 22.0;
    final throttleOffset = (throttlePosPct - 25.0).clamp(-20.0, 75.0) * 12.0;

    double optimalRpm = base + inclineOffset + loadOffset + throttleOffset;
    return optimalRpm.clamp(3800.0, 8400.0);
  }

  /// Hysteresis Buffer Engine:
  /// Evaluates whether to cue +1 (Upshift), -1 (Downshift), or 0 (Hold)
  static int evaluateHysteresisBuffer({
    required double currentRpm,
    required double optimalShiftRpm,
    required int currentGear,
    required double engineLoadPct,
  }) {
    // 1. Lugging Prevention (Downshift needed)
    // Low RPM under high mechanical load is destructive to single-cylinder 400cc engines
    if (currentRpm < luggingRpmLimit && engineLoadPct > luggingLoadThreshold && currentGear > 1) {
      return -1;
    }

    // 2. Dynamic Upshift Cue: Current RPM exceeds dynamic AI target + 250 RPM hysteresis
    if (currentRpm > (optimalShiftRpm + hysteresisBufferRpm) && currentGear < 6) {
      return 1;
    }

    // 3. Cruising / Steady state in powerband
    return 0;
  }
}

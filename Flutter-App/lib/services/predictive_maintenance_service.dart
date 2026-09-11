class MaintenanceItem {
  final String name;
  final double currentHealthPct;
  final double thresholdWarningPct;
  final String statusDescription;
  final String recommendation;

  const MaintenanceItem({
    required this.name,
    required this.currentHealthPct,
    this.thresholdWarningPct = 25.0,
    required this.statusDescription,
    required this.recommendation,
  });

  bool get isWarning => currentHealthPct <= thresholdWarningPct;
}

class PredictiveMaintenanceService {
  /// Evaluates condition-based wear rather than fixed distance
  static List<MaintenanceItem> evaluateCondition({
    required double totalDistanceKm,
    required double mechanicalStressIndex,
    required int luggingEvents,
    required int overRevEvents,
    required int aggressiveCornerExits,
  }) {
    // 1. Engine Oil Life (degrades faster with thermal stress, over-revs, and lugging)
    final thermalStressFactor = (overRevEvents * 0.15) + (luggingEvents * 0.10) + (mechanicalStressIndex * 0.08);
    final oilLife = (98.0 - (totalDistanceKm * 0.05) - thermalStressFactor).clamp(5.0, 100.0);

    // 2. Brake Pad Wear (degrades faster with harsh deceleration and corner exits)
    final brakeStressFactor = aggressiveCornerExits * 0.20;
    final brakeLife = (95.0 - (totalDistanceKm * 0.04) - brakeStressFactor).clamp(10.0, 100.0);

    // 3. Drive Chain & Sprocket Life (degrades with sudden torque spikes / lugging)
    final chainStressFactor = (luggingEvents * 0.25) + (aggressiveCornerExits * 0.15);
    final chainLife = (96.5 - (totalDistanceKm * 0.03) - chainStressFactor).clamp(10.0, 100.0);

    // 4. Spark Plug & Combustion Chamber Condition
    final carbonDepositFactor = (luggingEvents * 0.18);
    final sparkLife = (97.0 - (totalDistanceKm * 0.02) - carbonDepositFactor).clamp(15.0, 100.0);

    return [
      MaintenanceItem(
        name: 'Engine Oil & Filter',
        currentHealthPct: double.parse(oilLife.toStringAsFixed(1)),
        thresholdWarningPct: 20.0,
        statusDescription: oilLife > 50 ? 'Optimal Lubricity' : (oilLife > 20 ? 'Moderate Viscosity Shear' : 'Critical Degradation'),
        recommendation: oilLife > 20 ? 'Service scheduled in ${(oilLife * 35).round()} km' : 'Immediate Oil Flush Required',
      ),
      MaintenanceItem(
        name: 'Brake Pads (Sintered)',
        currentHealthPct: double.parse(brakeLife.toStringAsFixed(1)),
        thresholdWarningPct: 25.0,
        statusDescription: brakeLife > 40 ? 'Sufficient Friction Material' : 'Pad Thickness Low',
        recommendation: brakeLife > 25 ? 'Inspect at next service' : 'Replace front caliper pads soon',
      ),
      MaintenanceItem(
        name: 'O-Ring Drive Chain Slack',
        currentHealthPct: double.parse(chainLife.toStringAsFixed(1)),
        thresholdWarningPct: 30.0,
        statusDescription: chainLife > 40 ? 'Tension within OEM Spec (25-30mm)' : 'Excessive Slack Detected',
        recommendation: chainLife > 30 ? 'Clean & lubricate every 500 km' : 'Adjust chain tension immediately',
      ),
      MaintenanceItem(
        name: 'Spark Plug & Combustion',
        currentHealthPct: double.parse(sparkLife.toStringAsFixed(1)),
        thresholdWarningPct: 25.0,
        statusDescription: carbonDepositFactor < 5 ? 'Clean Electrodes' : 'Minor Carbon Fouling',
        recommendation: 'Check electrode gap at 10,000 km interval',
      ),
    ];
  }
}

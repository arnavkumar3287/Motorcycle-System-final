import 'dart:math';
import '../models/telemetry_frame.dart';

class RiderProfiler {
  // Normalized Cluster Centers derived from Scikit-Learn K-Means (k=3)
  // Features: [throttle_pos_pct, engine_rpm, vehicle_speed_kmh, lateral_accel_g, longitudinal_accel_g]
  static const List<List<double>> clusterCenters = [
    // Eco Profile: gentle throttle (~25%), moderate RPM (~3500), low G
    [24.5, 3600.0, 48.0, 0.12, 0.10],
    // Touring Profile: steady cruising (~45%), medium RPM (~5200), balanced G
    [46.0, 5250.0, 78.0, 0.22, 0.20],
    // Aggressive Profile: rapid throttle roll-on (>65%), high RPM (>7000), sharp cornering G
    [72.0, 7200.0, 115.0, 0.38, 0.35],
  ];

  static RiderStyle classifyRiderHabit({
    required double throttlePosPct,
    required double engineRpm,
    required double vehicleSpeedKmh,
    required double lateralAccelG,
    required double longitudinalAccelG,
  }) {
    final sample = [
      throttlePosPct,
      engineRpm,
      vehicleSpeedKmh,
      lateralAccelG,
      longitudinalAccelG,
    ];

    // Feature normalization scaling factors
    final weights = [1.0 / 100.0, 1.0 / 9000.0, 1.0 / 140.0, 1.0 / 1.0, 1.0 / 1.0];

    double minDistance = double.infinity;
    int closestCluster = 1;

    for (int c = 0; c < clusterCenters.length; c++) {
      double dist = 0.0;
      for (int f = 0; f < 5; f++) {
        final diff = (sample[f] - clusterCenters[c][f]) * weights[f];
        dist += diff * diff;
      }
      dist = sqrt(dist);

      if (dist < minDistance) {
        minDistance = dist;
        closestCluster = c;
      }
    }

    switch (closestCluster) {
      case 0:
        return RiderStyle.eco;
      case 2:
        return RiderStyle.aggressive;
      case 1:
      default:
        return RiderStyle.touring;
    }
  }

  static String getStyleName(RiderStyle style) {
    switch (style) {
      case RiderStyle.eco:
        return '🌱 Eco Commuter';
      case RiderStyle.aggressive:
        return '⚡ Aggressive Sport';
      case RiderStyle.touring:
        return '🛣️ Touring Cruiser';
    }
  }
}

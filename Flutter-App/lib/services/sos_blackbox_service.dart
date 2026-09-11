import 'dart:async';
import 'dart:collection';
import '../models/telemetry_frame.dart';
import '../models/ride_metrics.dart';

class SosBlackboxService {
  static const int bufferCapacity = 600; // 60 seconds at 10 Hz
  final Queue<TelemetryFrame> _rollingBuffer = Queue<TelemetryFrame>();

  final List<CrashEventBlackbox> _lockedIncidents = [];
  List<CrashEventBlackbox> get lockedIncidents => List.unmodifiable(_lockedIncidents);

  bool _isIncidentLocked = false;
  bool get isIncidentLocked => _isIncidentLocked;

  final StreamController<CrashEventBlackbox> _sosTriggerController = StreamController<CrashEventBlackbox>.broadcast();
  Stream<CrashEventBlackbox> get sosTriggerStream => _sosTriggerController.stream;

  void ingestFrame(TelemetryFrame frame, {double latitude = 18.6517, double longitude = 73.7615}) {
    if (_rollingBuffer.length >= bufferCapacity) {
      _rollingBuffer.removeFirst();
    }
    _rollingBuffer.addLast(frame);

    // Evaluate crash criteria
    final totalG = (frame.longitudinalAccelG.abs() + frame.lateralAccelG.abs());
    final isSevereSpike = totalG >= 4.5;
    final isBikeDown = frame.leanAngleDeg.abs() >= 80.0 && frame.vehicleSpeedKmh > 10.0;

    if ((isSevereSpike || isBikeDown) && !_isIncidentLocked) {
      _triggerSosAndLockBlackbox(frame, latitude, longitude);
    }
  }

  void _triggerSosAndLockBlackbox(TelemetryFrame triggeringFrame, double lat, double lon) {
    _isIncidentLocked = true;

    final incident = CrashEventBlackbox(
      timestamp: DateTime.now(),
      peakGForce: (triggeringFrame.longitudinalAccelG.abs() + triggeringFrame.lateralAccelG.abs()),
      peakLeanAngle: triggeringFrame.leanAngleDeg,
      speedKmh: triggeringFrame.vehicleSpeedKmh,
      latitude: lat,
      longitude: lon,
      preCrashTelemetry: _rollingBuffer.toList(),
    );

    _lockedIncidents.add(incident);
    _sosTriggerController.add(incident);
  }

  void unlockIncident() {
    _isIncidentLocked = false;
  }

  void dispose() {
    _sosTriggerController.close();
  }
}

import 'dart:async';

enum ObdConnectionState { disconnected, scanning, connecting, connected, error }

class ObdService {
  ObdConnectionState _state = ObdConnectionState.disconnected;
  ObdConnectionState get state => _state;

  final StreamController<ObdConnectionState> _stateController = StreamController<ObdConnectionState>.broadcast();
  Stream<ObdConnectionState> get stateStream => _stateController.stream;

  // Live parsed values
  double currentRpm = 0.0;
  double currentSpeedKmh = 0.0;
  double currentEngineLoadPct = 0.0;
  double currentThrottlePosPct = 0.0;

  void setState(ObdConnectionState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  /// Parses raw ELM327 hex responses
  /// Example RPM response: "41 0C 1A F8" -> A=0x1A (26), B=0xF8 (248) -> ((26*256)+248)/4 = 1726 RPM
  double? parseRpmResponse(String raw) {
    try {
      final clean = raw.replaceAll(' ', '').toUpperCase();
      final index = clean.indexOf('410C');
      if (index != -1 && clean.length >= index + 8) {
        final a = int.parse(clean.substring(index + 4, index + 6), radix: 16);
        final b = int.parse(clean.substring(index + 6, index + 8), radix: 16);
        return ((a * 256.0) + b) / 4.0;
      }
    } catch (_) {}
    return null;
  }

  /// Example Speed response: "41 0D 4B" -> A=0x4B (75) -> 75 km/h
  double? parseSpeedResponse(String raw) {
    try {
      final clean = raw.replaceAll(' ', '').toUpperCase();
      final index = clean.indexOf('410D');
      if (index != -1 && clean.length >= index + 6) {
        final a = int.parse(clean.substring(index + 4, index + 6), radix: 16);
        return a.toDouble();
      }
    } catch (_) {}
    return null;
  }

  /// Example Load response: "41 04 80" -> A=0x80 (128) -> (128*100)/255 = 50.2%
  double? parseEngineLoadResponse(String raw) {
    try {
      final clean = raw.replaceAll(' ', '').toUpperCase();
      final index = clean.indexOf('4104');
      if (index != -1 && clean.length >= index + 6) {
        final a = int.parse(clean.substring(index + 4, index + 6), radix: 16);
        return (a * 100.0) / 255.0;
      }
    } catch (_) {}
    return null;
  }

  /// Example Throttle response: "41 11 66" -> A=0x66 (102) -> (102*100)/255 = 40.0%
  double? parseThrottlePosResponse(String raw) {
    try {
      final clean = raw.replaceAll(' ', '').toUpperCase();
      final index = clean.indexOf('4111');
      if (index != -1 && clean.length >= index + 6) {
        final a = int.parse(clean.substring(index + 4, index + 6), radix: 16);
        return (a * 100.0) / 255.0;
      }
    } catch (_) {}
    return null;
  }

  void dispose() {
    _stateController.close();
  }
}

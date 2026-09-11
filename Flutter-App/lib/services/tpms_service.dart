import 'dart:async';

class TireData {
  final double pressurePsi;
  final double temperatureC;
  final int batteryPct;
  final bool isCold;
  final bool isLowPressure;

  const TireData({
    required this.pressurePsi,
    required this.temperatureC,
    this.batteryPct = 95,
    this.isCold = false,
    this.isLowPressure = false,
  });
}

class TpmsService {
  TireData frontTire = const TireData(pressurePsi: 29.5, temperatureC: 22.0, isCold: true);
  TireData rearTire = const TireData(pressurePsi: 32.0, temperatureC: 23.5, isCold: true);

  final StreamController<Map<String, TireData>> _streamController = StreamController<Map<String, TireData>>.broadcast();
  Stream<Map<String, TireData>> get tireStream => _streamController.stream;

  /// Decodes typical BLE TPMS manufacturer broadcast byte packet
  /// Format: [Header, ID, Pressure (kPa or PSI), Temperature (offset +40), Flags, CRC]
  void parseBleAdvertisement(List<int> bytes, {required bool isFront}) {
    if (bytes.length < 6) return;

    try {
      // Byte 2 & 3: Pressure (kPa / 6.895 = PSI)
      final rawPressure = (bytes[2] << 8) | bytes[3];
      final psi = (rawPressure / 10.0) * 0.145038;

      // Byte 4: Temperature (°C with +40 offset)
      final tempC = bytes[4] - 40.0;

      final data = TireData(
        pressurePsi: double.parse(psi.toStringAsFixed(1)),
        temperatureC: double.parse(tempC.toStringAsFixed(1)),
        isCold: tempC < 25.0,
        isLowPressure: psi < 26.0,
      );

      if (isFront) {
        frontTire = data;
      } else {
        rearTire = data;
      }

      _streamController.add({'front': frontTire, 'rear': rearTire});
    } catch (_) {}
  }

  void updateTires(TireData front, TireData rear) {
    frontTire = front;
    rearTire = rear;
    _streamController.add({'front': frontTire, 'rear': rearTire});
  }

  void dispose() {
    _streamController.close();
  }
}

/// Where the location stream comes from.
enum TrackingSourceMode {
  /// Phone GPS only. No BLE link is opened.
  phoneGps,

  /// External ELD over BLE. Phone GPS is ignored while the device is connected.
  bleDevice,

  /// BLE when available, phone GPS as fallback (recommended for mixed fleets).
  hybrid;

  bool get usesBluetooth => this != TrackingSourceMode.phoneGps;

  bool get usesPhoneGps => this != TrackingSourceMode.bleDevice;

  static TrackingSourceMode fromWire(String? value) {
    return switch (value) {
      'phoneGps' => TrackingSourceMode.phoneGps,
      'hybrid' => TrackingSourceMode.hybrid,
      _ => TrackingSourceMode.bleDevice,
    };
  }
}

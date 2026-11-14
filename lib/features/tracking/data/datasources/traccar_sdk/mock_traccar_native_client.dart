import 'traccar_native_client.dart';

class MockTraccarNativeClient implements TraccarNativeClient {
  bool _isTracking = false;

  @override
  Future<void> configure(Map<String, dynamic> config) async {}

  @override
  Future<void> startBackgroundTracking() async {
    _isTracking = true;
  }

  @override
  Future<void> stopBackgroundTracking() async {
    _isTracking = false;
  }

  @override
  Future<bool> isTrackingActive() async => _isTracking;

  @override
  Future<void> requestImmediatePosition({String? alarm}) async {}

  @override
  Future<void> pushLocation(Map<String, dynamic> location) async {}

  @override
  Future<Map<String, dynamic>?> getLastKnownPosition() async => null;

  @override
  Future<List<Map<String, dynamic>>> getNativeLogs() async => [];

  @override
  Future<void> clearNativeLogs() async {}
}

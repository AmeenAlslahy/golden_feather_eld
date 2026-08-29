class TraccarClientSdk {
  Future<void> setConfig(Config config) async {}
  Future<void> start() async {}
  Future<void> stop() async {}
  Future<bool> isTracking() async => false;
  Future<void> requestPosition({String? alarm}) async {}
  Future<List<LogEntry>> getLogs() async => [];
  Future<void> clearLogs() async {}
}

class Config {
  final String serverUrl;
  final String deviceId;
  final LocationConfig location;
  final bool wakeLock;
  final bool buffer;
  final bool preferPlatformProviders;

  Config({
    required this.serverUrl,
    required this.deviceId,
    required this.location,
    required this.wakeLock,
    required this.buffer,
    required this.preferPlatformProviders,
  });
}

class LocationConfig {
  final Accuracy accuracy;
  final int distanceMeters;
  final int intervalSeconds;
  final int angleDegrees;
  final int heartbeatIntervalSeconds;
  final bool stopDetection;

  LocationConfig({
    required this.accuracy,
    required this.distanceMeters,
    required this.intervalSeconds,
    required this.angleDegrees,
    required this.heartbeatIntervalSeconds,
    required this.stopDetection,
  });
}

enum Accuracy { highest, high, medium, low }
class LogEntry {}

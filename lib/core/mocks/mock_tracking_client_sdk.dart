import 'dart:async';

/// محاكاة لإعدادات الموقع الخاصة بالحزمة
class LocationConfig {
  final String accuracy;
  final int distanceMeters;
  final int intervalSeconds;
  final int angleDegrees;
  final int heartbeatIntervalSeconds;
  final bool stopDetection;

  LocationConfig({
    this.accuracy = 'medium',
    this.distanceMeters = 75,
    this.intervalSeconds = 300,
    this.angleDegrees = 0,
    this.heartbeatIntervalSeconds = 0,
    this.stopDetection = true,
  });
}

/// محاكاة للكائن Config الخاص بالحزمة
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
    this.wakeLock = false,
    this.buffer = true,
    this.preferPlatformProviders = false,
  });
}

/// محاكاة للـ TraccarClientSdk
class TraccarClientSdk {
  static final TraccarClientSdk _instance = TraccarClientSdk._internal();
  factory TraccarClientSdk() => _instance;
  TraccarClientSdk._internal();

  Config? _config;
  bool _isRunning = false;
  Timer? _mockTimer;

  // Stream لتمرير المواقع إلى التطبيق
  final _locationController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onLocationUpdate => _locationController.stream;

  Future<void> init(Config config) async {
    _config = config;
  }

  Future<void> setConfig(Config config) async {
    _config = config;
  }

  Future<void> start() async {
    _isRunning = true;
    _mockTimer?.cancel();
    _mockTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isRunning) {
        _locationController.add({
          'latitude': 24.7136 + (timer.tick * 0.0001),
          'longitude': 46.6753 + (timer.tick * 0.0001),
          'speed': 60.0,
          'accuracy': 10.0,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  Future<void> stop() async {
    _isRunning = false;
    _mockTimer?.cancel();
  }

  Future<void> requestPosition() async {
    _locationController.add({
      'latitude': 24.7136,
      'longitude': 46.6753,
      'speed': 0.0,
      'accuracy': 5.0,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

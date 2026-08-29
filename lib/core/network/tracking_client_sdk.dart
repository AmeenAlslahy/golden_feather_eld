import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_environment.dart';

enum Accuracy { highest, high, medium, low }

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

  Map<String, dynamic> toMap() {
    return {
      'accuracy': accuracy.name,
      'distanceMeters': distanceMeters,
      'intervalSeconds': intervalSeconds,
      'angleDegrees': angleDegrees,
      'heartbeatIntervalSeconds': heartbeatIntervalSeconds,
      'stopDetection': stopDetection,
    };
  }
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

  Map<String, dynamic> toMap() {
    return {
      'serverUrl': serverUrl,
      'deviceId': deviceId,
      'location': location.toMap(),
      'wakeLock': wakeLock,
      'buffer': buffer,
      'preferPlatformProviders': preferPlatformProviders,
    };
  }
}

class LogMessage {
  final int time;
  final String message;
  LogMessage({required this.time, required this.message});
}

abstract class TrackingClientInterface {
  Future<void> setConfig(Config config);
  Future<void> start();
  Future<void> stop();
  Future<bool> isTracking();
  Future<void> requestPosition({String? alarm});
  Future<List<LogMessage>> getLogs();
  Future<void> clearLogs();
}

class RealTrackingClient implements TrackingClientInterface {
  static const MethodChannel _channel =
      MethodChannel('com.goldenfeather.eld/traccar');

  @override
  Future<void> setConfig(Config config) async {
    await _channel.invokeMethod('setConfig', config.toMap());
  }

  @override
  Future<void> start() async {
    await _channel.invokeMethod('start');
  }

  @override
  Future<void> stop() async {
    await _channel.invokeMethod('stop');
  }

  @override
  Future<bool> isTracking() async {
    final result = await _channel.invokeMethod<bool>('isTracking');
    return result ?? false;
  }

  @override
  Future<void> requestPosition({String? alarm}) async {
    await _channel.invokeMethod('requestPosition', {'alarm': alarm});
  }

  @override
  Future<List<LogMessage>> getLogs() async {
    final logs = await _channel.invokeMethod<List<dynamic>>('getLogs');
    if (logs == null) return [];
    return logs.map((log) {
      final map = Map<String, dynamic>.from(log as Map);
      return LogMessage(
          time: map['time'] as int, message: map['message'] as String);
    }).toList();
  }

  @override
  Future<void> clearLogs() async {
    await _channel.invokeMethod('clearLogs');
  }
}

class MockTrackingClient implements TrackingClientInterface {
  bool _isTracking = false;

  @override
  Future<void> setConfig(Config config) async {}

  @override
  Future<void> start() async {
    _isTracking = true;
  }

  @override
  Future<void> stop() async {
    _isTracking = false;
  }

  @override
  Future<bool> isTracking() async => _isTracking;

  @override
  Future<void> requestPosition({String? alarm}) async {}

  @override
  Future<List<LogMessage>> getLogs() async => [];

  @override
  Future<void> clearLogs() async {}
}

final trackingClientProvider = Provider<TrackingClientInterface>((ref) {
  if (AppEnvironmentConfig.current == AppEnvironment.mock) {
    return MockTrackingClient();
  }
  return RealTrackingClient();
});

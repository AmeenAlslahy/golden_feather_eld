import 'package:flutter/services.dart';
import '../../../../../core/utils/logger.dart';
import 'traccar_native_client.dart';

class TraccarNativeClientImpl implements TraccarNativeClient {
  static const MethodChannel _channel =
      MethodChannel('com.goldenfeather.eld/traccar');

  @override
  Future<void> configure(Map<String, dynamic> config) async {
    try {
      await _channel.invokeMethod('setConfig', config);
    } on PlatformException catch (e) {
      AppLogger.error('Failed to configure native tracking: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> startBackgroundTracking() async {
    try {
      await _channel.invokeMethod('start');
    } on PlatformException catch (e) {
      AppLogger.error('Failed to start native tracking: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> stopBackgroundTracking() async {
    try {
      await _channel.invokeMethod('stop');
    } on PlatformException catch (e) {
      AppLogger.error('Failed to stop native tracking: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<bool> isTrackingActive() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isTracking');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> requestImmediatePosition({String? alarm}) async {
    try {
      await _channel.invokeMethod('requestPosition', {'alarm': alarm});
    } on PlatformException catch (e) {
      AppLogger.error('Failed to request immediate position: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getNativeLogs() async {
    try {
      final List<dynamic>? result =
          await _channel.invokeMethod<List<dynamic>>('getLogs');
      if (result == null) return [];
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on PlatformException {
      return [];
    }
  }

  @override
  Future<void> clearNativeLogs() async {
    try {
      await _channel.invokeMethod('clearLogs');
    } on PlatformException catch (e) {
      AppLogger.error('Failed to clear native logs: ${e.message}');
    }
  }
}

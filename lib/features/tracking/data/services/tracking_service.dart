import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/traccar_sdk/traccar_native_client.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/utils/logger.dart';

/// خدمة التتبع - متكاملة مع Traccar Client SDK
class TrackingService {
  final TraccarNativeClient _tracker;
  final LocalStorageService _storage;
  StreamSubscription? _locationSubscription;
  bool _isInitialized = false;

  TrackingService({
    required TraccarNativeClient tracker,
    required LocalStorageService storage,
  })  : _tracker = tracker,
        _storage = storage;

  // ========== التهيئة ==========

  /// تهيئة المتتبع مع الإعدادات الحالية
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final config = _buildConfig();

      // لا تسمح ببدء التتبع بعنوان وهمي أو فارغ في بيئة temporaryTraccar
      if (AppEnvironmentConfig.current == AppEnvironment.temporaryTraccar) {
        if (config['serverUrl'].isEmpty ||
            config['serverUrl'].contains('mock-traccar-server')) {
          AppLogger.error(
              '❌ Tracking blocked: Invalid or Mock URL used in temporaryTraccar');
          throw Exception(
              'Configuration Error: Valid Server URL required for temporaryTraccar');
        }
      }

      await _tracker.configure(config);
      _isInitialized = true;
      AppLogger.info('✅ TrackingService initialized with Traccar SDK');
      AppLogger.info('   Server: ${config['serverUrl']}');
      AppLogger.info('   Device: ${config['deviceId']}');
    } catch (e) {
      AppLogger.error('❌ Failed to initialize Traccar SDK', e);
      rethrow;
    }
  }

  /// بناء Config من الإعدادات المحلية أو البيئة
  Map<String, dynamic> _buildConfig() {
    String serverUrl = _storage.serverUrl;

    // في temporaryTraccar نفضل URL البيئة لتجنب mock المخزن محلياً
    if (AppEnvironmentConfig.current == AppEnvironment.temporaryTraccar) {
      if (serverUrl.isEmpty || serverUrl.contains('mock-traccar-server')) {
        serverUrl = AppEnvironmentConfig.apiBaseUrl;
      }
    }

    // Ensure tracking uses the OsmAnd port instead of the Web/API port.
    const osmAndPort = AppEnvironmentConfig.osmAndPort;
    try {
      final uri = Uri.parse(serverUrl);
      if (uri.port != osmAndPort) {
        serverUrl = uri.replace(port: osmAndPort, path: '/').toString();
      }
    } catch (_) {}

    return {
      'serverUrl': serverUrl,
      'deviceId': _storage.deviceId,
      'location': {
        'accuracy': _mapAccuracy(_storage.accuracy),
        'distanceMeters': _storage.distance,
        'intervalSeconds': _storage.interval,
        'angleDegrees': _storage.angle,
        'heartbeatIntervalSeconds': _storage.heartbeat,
        'stopDetection': _storage.stopDetection,
      },
      'wakeLock': _storage.wakelock,
      'buffer': _storage.buffer,
      'preferPlatformProviders': _storage.preferPlatformProviders,
    };
  }

  String _mapAccuracy(String accuracy) {
    return switch (accuracy) {
      'highest' => 'highest',
      'high' => 'high',
      'low' => 'low',
      _ => 'medium',
    };
  }

  // ========== التحكم في التتبع ==========

  /// بدء التتبع
  Future<void> start() async {
    if (!_isInitialized) await init();
    try {
      await _tracker.startBackgroundTracking();
      AppLogger.info('📍 Tracking started');
    } catch (e) {
      AppLogger.error('Failed to start tracking', e);
      rethrow;
    }
  }

  /// إيقاف التتبع
  Future<void> stop() async {
    try {
      await _tracker.stopBackgroundTracking();
      AppLogger.info('⏹️ Tracking stopped');
    } catch (e) {
      AppLogger.error('Failed to stop tracking', e);
      rethrow;
    }
  }

  /// هل التتبع نشط
  Future<bool> isTracking() async {
    try {
      return await _tracker.isTrackingActive();
    } catch (e) {
      return false;
    }
  }

  /// طلب الموقع الحالي
  Future<void> requestPosition({String? alarm}) async {
    if (!_isInitialized) await init();
    try {
      await _tracker.requestImmediatePosition(alarm: alarm);
      AppLogger.info(
          '📍 Position requested${alarm != null ? " with alarm: $alarm" : ""}');
    } catch (e) {
      AppLogger.error('Failed to request position', e);
      rethrow;
    }
  }

  /// تحديث الإعدادات
  Future<void> updateConfig() async {
    if (!_isInitialized) await init();
    try {
      final config = _buildConfig();
      await _tracker.configure(config);
      _isInitialized = true;
      AppLogger.info('⚙️ Tracking config updated');
    } catch (e) {
      AppLogger.error('Failed to update config', e);
      rethrow;
    }
  }

  // ========== السجلات ==========

  /// الحصول على سجلات التتبع
  Future<List<Map<String, dynamic>>> getLogs() async {
    try {
      return await _tracker.getNativeLogs();
    } catch (e) {
      // In production, we don't mock logs anymore
      AppLogger.error('Failed to get logs from native tracker', e);
      return [];
    }
  }

  /// مسح السجلات
  Future<void> clearLogs() async {
    try {
      await _tracker.clearNativeLogs();
      AppLogger.info('🗑️ Logs cleared');
    } catch (e) {
      AppLogger.error('Failed to clear logs', e);
    }
  }

  // ========== التخلص ==========

  void dispose() {
    _locationSubscription?.cancel();
    _isInitialized = false;
    AppLogger.info('TrackingService disposed');
  }
}

/// مزود خدمة التتبع
final trackingServiceProvider = Provider<TrackingService>((ref) {
  final storage = ref.watch(localStorageProvider);
  final tracker = ref.watch(traccarNativeClientProvider);
  return TrackingService(storage: storage, tracker: tracker);
});

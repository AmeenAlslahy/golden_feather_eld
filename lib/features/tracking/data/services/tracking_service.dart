import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/traccar_sdk/traccar_native_client.dart';
import '../../../../backend/providers/backend_network_providers.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/services/bluetooth_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/utils/logger.dart';
import '../../../hardware/data/datasources/ble_location_data_source.dart';
import '../../domain/tracking_source_mode.dart';

/// خدمة التتبع - متكاملة مع Traccar Client SDK
class TrackingService {
  final TraccarNativeClient _tracker;
  final LocalStorageService _storage;
  final BleLocationDataSource? _bleIngestion;
  StreamSubscription? _locationSubscription;
  bool _isInitialized = false;

  /// بصمة آخر إعدادات طُبّقت فعلياً على الـ SDK الأصلي.
  ///
  /// كانت كل نداءات `updateConfig` تعيد `configure` الأصلي حتى لو كانت
  /// القيم نفسها (تسجيل الدخول + ربط الجهاز + بدء التتبع في ثوانٍ واحدة).
  /// البصمة تُسقط التكرار قبل عبور جسر MethodChannel.
  String? _lastAppliedSignature;

  TrackingService({
    required TraccarNativeClient tracker,
    required LocalStorageService storage,
    BluetoothService? bluetoothService,
  }) : _tracker = tracker,
       _storage = storage,
       _bleIngestion = bluetoothService == null
           ? null
           : BleLocationDataSource(
               bluetoothService: bluetoothService,
               pushLocation: tracker.pushLocation,
             );

  // ========== التهيئة ==========

  /// تهيئة المتتبع مع الإعدادات الحالية
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final config = _buildConfig();
      _validateConfig(config);
      await _applyConfig(config);
      AppLogger.info('✅ TrackingService initialized with Traccar SDK');
      // لا نطبع serverUrl أو deviceId: بيانات حساسة تبقى في سجلات الجهاز.
    } catch (e) {
      AppLogger.error('❌ Failed to initialize Traccar SDK', e);
      rethrow;
    }
  }

  /// لا تسمح ببدء التتبع بعنوان وهمي أو فارغ في بيئة temporaryTraccar.
  void _validateConfig(Map<String, dynamic> config) {
    if (AppEnvironmentConfig.current != AppEnvironment.temporaryTraccar) {
      return;
    }
    if (config['serverUrl'].isEmpty ||
        config['serverUrl'].contains('mock-traccar-server')) {
      AppLogger.error(
        '❌ Tracking blocked: Invalid or Mock URL used in temporaryTraccar',
      );
      throw Exception(
        'Configuration Error: Valid Server URL required for temporaryTraccar',
      );
    }
  }

  /// بناء Config من الإعدادات المحلية أو البيئة
  Map<String, dynamic> _buildConfig() {
    String serverUrl = _storage.serverUrl;

    // Use environment apiBaseUrl if local serverUrl is empty or placeholder mock
    if (serverUrl.isEmpty || serverUrl.contains('mock-traccar-server')) {
      if (AppEnvironmentConfig.current == AppEnvironment.temporaryTraccar ||
          serverUrl.isEmpty) {
        serverUrl = AppEnvironmentConfig.apiBaseUrl;
      }
    }

    // Ensure tracking uses the OsmAnd port instead of the Web/API port, but do
    // not destroy a URL that already carries an explicit port (self-hosted
    // Traccar, reverse proxy) or an explicit OsmAnd path.
    const osmAndPort = AppEnvironmentConfig.osmAndPort;
    try {
      final uri = Uri.parse(serverUrl);
      if (uri.hasAuthority) {
        final hasExplicitPort = uri.hasPort;
        final explicitOsmAndPath = uri.path.contains('osmand');
        final needsPort = !hasExplicitPort;
        if (needsPort || explicitOsmAndPath) {
          final targetPort = needsPort ? osmAndPort : uri.port;
          final targetScheme =
              (needsPort && uri.scheme == 'https' && osmAndPort == 5055)
              ? 'http'
              : uri.scheme;
          final targetPath = explicitOsmAndPath ? uri.path : '/';
          serverUrl = uri
              .replace(scheme: targetScheme, port: targetPort, path: targetPath)
              .toString();
        }
      }
    } catch (e, st) {
      AppLogger.warning(
        'TrackingService: serverUrl "$serverUrl" could not be normalized to '
        'the OsmAnd port — using it as-is',
        e,
        st,
      );
    }

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
      'sourceMode': _sourceModeWire,
    };
  }

  /// Persisted transport mode, tolerant to uninitialised test doubles.
  String get _sourceModeWire {
    try {
      return _storage.trackingSourceMode;
    } catch (_) {
      return 'hybrid';
    }
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

  /// Whether BLE ingestion should run for the persisted transport mode.
  ///
  /// Storage is accessed defensively: test doubles and partially initialised
  /// services must not prevent phone tracking from starting.
  bool get _bleEnabled {
    if (_bleIngestion == null) return false;
    try {
      return TrackingSourceMode.fromWire(
        _storage.trackingSourceMode,
      ).usesBluetooth;
    } catch (_) {
      // Storage unavailable (test double / not initialised yet): do not open a
      // native BLE stream as a side effect. The next config pass retries.
      return false;
    }
  }

  void _syncBleIngestion() {
    final ingestion = _bleIngestion;
    if (ingestion == null) return;
    if (_bleEnabled) {
      ingestion.start();
    } else {
      ingestion.stop();
    }
  }

  /// Applies a transport-mode change immediately, without waiting for the next
  /// config pass. Called by the connection screen when the driver switches
  /// between phone GPS and the BLE ELD.
  void refreshSourceMode() => _syncBleIngestion();

  /// بدء التتبع
  Future<void> start() async {
    if (!_isInitialized) await init();
    try {
      await _tracker.startBackgroundTracking();
      _syncBleIngestion();
      AppLogger.info('📍 Tracking started');
    } catch (e) {
      AppLogger.error('Failed to start tracking', e);
      rethrow;
    }
  }

  /// إيقاف التتبع
  Future<void> stop() async {
    try {
      _bleIngestion?.stop();
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
        '📍 Position requested${alarm != null ? " with alarm: $alarm" : ""}',
      );
    } catch (e) {
      AppLogger.error('Failed to request position', e);
      rethrow;
    }
  }

  /// آخر موقع معروف من النظام — قراءة فقط.
  ///
  /// لا يستدعي `requestPosition` ولا يهيّئ SDK ولا يخزّن/يرفع؛ يعيد `null`
  /// إذا لم يوجد قفل حديث أو تعذّرت قراءته. الأخطاء تُبتلع لأن هذا بذر
  /// عرضي وليس عملية تتبع.
  Future<Map<String, dynamic>?> getLastKnownPosition() async {
    try {
      return await _tracker.getLastKnownPosition();
    } catch (e) {
      AppLogger.warning('Failed to read last known position', e);
      return null;
    }
  }

  /// تحديث الإعدادات
  ///
  /// idempotent: لا يعبر إلى الـ SDK الأصلي إذا كانت الإعدادات المبنية من
  /// التخزين مطابقة لآخر إعدادات طُبّقت. هذا يمنع التكرار الذي كان يحدث عند
  /// تسجيل الدخول (auth + ربط الجهاز + بدء التتبع) في نفس الثانية.
  Future<void> updateConfig() async {
    try {
      final config = _buildConfig();
      _validateConfig(config);
      final signature = _signatureOf(config);
      if (_isInitialized && signature == _lastAppliedSignature) {
        return;
      }
      await _applyConfig(config);
      _syncBleIngestion();
      AppLogger.info('⚙️ Tracking config updated');
    } catch (e) {
      AppLogger.error('Failed to update config', e);
      rethrow;
    }
  }

  Future<void> _applyConfig(Map<String, dynamic> config) async {
    await _tracker.configure(config);
    _lastAppliedSignature = _signatureOf(config);
    _isInitialized = true;
  }

  String _signatureOf(Map<String, dynamic> config) => jsonEncode(config);

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
    _bleIngestion?.stop();
    _locationSubscription?.cancel();
    _isInitialized = false;
    _lastAppliedSignature = null;
    AppLogger.info('TrackingService disposed');
  }
}

/// مزود خدمة التتبع
final trackingServiceProvider = Provider<TrackingService>((ref) {
  final storage = ref.watch(localStorageProvider);
  final tracker = ref.watch(traccarNativeClientProvider);
  final bluetoothService = ref.watch(bluetoothServiceProvider);
  return TrackingService(
    storage: storage,
    tracker: tracker,
    bluetoothService: bluetoothService,
  );
});

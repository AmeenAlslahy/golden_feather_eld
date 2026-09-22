import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/contracts/config_backend.dart';
import '../../backend/providers/backend_providers.dart';
import '../../features/tracking/data/services/tracking_service.dart';
import '../config/app_environment.dart';
import '../error/exception.dart';
import '../utils/logger.dart';
import 'local_storage_service.dart';

/// خدمة جلب الإعدادات عن بعد
class RemoteConfigService {
  final ConfigBackend _configBackend;
  final LocalStorageService _storage;
  final TrackingService _trackingService;

  RemoteConfigService({
    required ConfigBackend configBackend,
    required LocalStorageService storage,
    required TrackingService trackingService,
  })  : _configBackend = configBackend,
        _storage = storage,
        _trackingService = trackingService;

  /// جلب الإعدادات من الخادم
  Future<bool> fetchRemoteConfig() async {
    try {
      final baseUrl = AppEnvironmentConfig.apiBaseUrl;
      if (baseUrl.isEmpty || baseUrl.contains('mock-traccar-server')) {
        AppLogger.info(
            'ℹ️ Remote config aborted: Server URL is not configured or is mock');
        return false;
      }

      final deviceId = _storage.deviceId;
      if (deviceId.isEmpty) {
        AppLogger.warning('Cannot fetch config: no device ID');
        return false;
      }

      AppLogger.info('📡 Fetching remote config for device: $deviceId');

      // استخدام Endpoint واضح
      const String endpoint = '/api/server';

      try {
        final result = await _configBackend.getLegacyServerConfig();

        return await result.match(
          (failure) async {
            AppLogger.warning('Failed to fetch remote config: $failure');
            return false;
          },
          (config) async {
            // تطبيق الإعدادات
            await _applyConfig(config);
            AppLogger.info('✅ Remote config applied successfully');
            return true;
          },
        );
      } on ServerException catch (e) {
        if (e.statusCode == 404) {
          AppLogger.info(
              'ℹ️ Remote config not available for this device (404). Endpoint: $endpoint');
          return false;
        }
        AppLogger.warning(
            'Remote config API error: ${e.statusCode} for endpoint: $endpoint');
        return false;
      }
    } catch (e) {
      AppLogger.error('Error fetching remote config', e);
      return false;
    }
  }

  /// تطبيق الإعدادات المستلمة
  Future<void> _applyConfig(Map<String, dynamic> config) async {
    // تحديث الإعدادات المحلية
    if (config['server_url'] != null) {
      await _storage.setServerUrl(config['server_url']);
    }
    if (config['accuracy'] != null) {
      await _storage.setAccuracy(config['accuracy']);
    }
    if (config['interval'] != null) {
      await _storage.setInterval(config['interval']);
    }
    if (config['distance'] != null) {
      await _storage.setDistance(config['distance']);
    }
    if (config['angle'] != null) {
      await _storage.setAngle(config['angle']);
    }
    if (config['heartbeat'] != null) {
      await _storage.setHeartbeat(config['heartbeat']);
    }
    if (config['buffer'] != null) {
      await _storage.setBuffer(config['buffer']);
    }
    if (config['wakelock'] != null) {
      await _storage.setWakelock(config['wakelock']);
    }
    if (config['stop_detection'] != null) {
      await _storage.setStopDetection(config['stop_detection']);
    }
    // TODO(Phase5): reimplement password management.

    // تحديث المتتبع مباشرة
    await _trackingService.updateConfig();
  }

  /// جلب التكوين عند بدء التطبيق
  static Future<void> fetchOnStartup(ProviderContainer container) async {
    final service = RemoteConfigService(
      configBackend: container.read(configBackendProvider),
      storage: container.read(localStorageProvider),
      trackingService: container.read(trackingServiceProvider),
    );

    final success = await service.fetchRemoteConfig();
    if (success) {
      AppLogger.info('✅ Remote config fetched on startup');
    } else {
      AppLogger.info(
          'ℹ️ Using local config (remote fetch failed or not available)');
    }
  }
}

/// مزود خدمة التكوين عن بعد
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService(
    configBackend: ref.read(configBackendProvider),
    storage: ref.read(localStorageProvider),
    trackingService: ref.read(trackingServiceProvider),
  );
});

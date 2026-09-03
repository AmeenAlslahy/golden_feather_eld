import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import 'local_storage_service.dart';

class TrackingConfigStorageService {
  final SharedPreferencesWithCache _prefs;

  TrackingConfigStorageService(this._prefs);

  // Keys
  static const String _deviceIdKey = 'id';
  static const String _serverUrlKey = 'url';
  static const String _accuracyKey = 'accuracy';
  static const String _distanceKey = 'distance';
  static const String _intervalKey = 'interval';
  static const String _angleKey = 'angle';
  static const String _heartbeatKey = 'heartbeat';
  static const String _bufferKey = 'buffer';
  static const String _wakelockKey = 'wakelock';
  static const String _stopDetectionKey = 'stop_detection';
  static const String _preferPlatformProvidersKey = 'prefer_platform_providers';
  static const String _backendTypeKey = 'backend_type';

  // Getters
  String get deviceId => _prefs.getString(_deviceIdKey) ?? '';
  String get serverUrl => _prefs.getString(_serverUrlKey) ?? '';
  String get accuracy => _prefs.getString(_accuracyKey) ?? 'medium';
  int get distance => _prefs.getInt(_distanceKey) ?? AppConstants.defaultDistanceMeters.toInt();
  int get interval => _prefs.getInt(_intervalKey) ?? AppConstants.defaultIntervalSeconds;
  int get angle => _prefs.getInt(_angleKey) ?? 0;
  int get heartbeat => _prefs.getInt(_heartbeatKey) ?? 0;
  bool get buffer => _prefs.getBool(_bufferKey) ?? true;
  bool get wakelock => _prefs.getBool(_wakelockKey) ?? false;
  bool get stopDetection => _prefs.getBool(_stopDetectionKey) ?? true;
  bool get preferPlatformProviders => _prefs.getBool(_preferPlatformProvidersKey) ?? false;
  String get backendType => _prefs.getString(_backendTypeKey) ?? 'traccar';

  // Setters
  Future<void> setDeviceId(String value) => _prefs.setString(_deviceIdKey, value);
  Future<void> setServerUrl(String value) => _prefs.setString(_serverUrlKey, value);
  Future<void> setAccuracy(String value) => _prefs.setString(_accuracyKey, value);
  Future<void> setDistance(int value) => _prefs.setInt(_distanceKey, value);
  Future<void> setInterval(int value) => _prefs.setInt(_intervalKey, value);
  Future<void> setAngle(int value) => _prefs.setInt(_angleKey, value);
  Future<void> setHeartbeat(int value) => _prefs.setInt(_heartbeatKey, value);
  Future<void> setBuffer(bool value) => _prefs.setBool(_bufferKey, value);
  Future<void> setWakelock(bool value) => _prefs.setBool(_wakelockKey, value);
  Future<void> setStopDetection(bool value) => _prefs.setBool(_stopDetectionKey, value);
  Future<void> setPreferPlatformProviders(bool value) => _prefs.setBool(_preferPlatformProvidersKey, value);
  Future<void> setBackendType(String value) => _prefs.setString(_backendTypeKey, value);

  /// Apply settings from URI
  Future<void> applyFromUri(Uri uri) async {
    final params = uri.queryParameters;

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      await setServerUrl('${uri.origin}${uri.path}');
    } else {
      final url = params['url'];
      if (url != null) await setServerUrl(url);
    }

    if (params['id'] != null) await setDeviceId(params['id']!);
    if (params['accuracy'] != null) await setAccuracy(params['accuracy']!);
    if (params['interval'] != null) await setInterval(int.tryParse(params['interval']!) ?? interval);
    if (params['distance'] != null) await setDistance(int.tryParse(params['distance']!) ?? distance);
    if (params['angle'] != null) await setAngle(int.tryParse(params['angle']!) ?? angle);
    if (params['heartbeat'] != null) await setHeartbeat(int.tryParse(params['heartbeat']!) ?? heartbeat);
    if (params['buffer'] != null) await setBuffer(params['buffer'] == 'true');
    if (params['wakelock'] != null) await setWakelock(params['wakelock'] == 'true');
    if (params['stopDetection'] != null) await setStopDetection(params['stopDetection'] == 'true');
    if (params['preferPlatformProviders'] != null) {
      await setPreferPlatformProviders(params['preferPlatformProviders'] == 'true');
    }
  }
}

final trackingConfigStorageProvider = Provider<TrackingConfigStorageService>((ref) {
  // We temporarily read from the existing local storage provider to get the shared prefs instance.
  // In the future, this should depend on a dedicated SharedPreferences provider.
  final localStorage = ref.watch(localStorageProvider);
  return TrackingConfigStorageService(localStorage.prefs);
});

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../network/tracking_client_sdk.dart';
import '../utils/logger.dart';

/// خدمة التخزين المحلي - نسخة محسنة من Preferences الأصلي
class LocalStorageService {
  static Future<void>? _initFuture;
  static late SharedPreferencesWithCache _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  bool _initialized = false;

  // مفاتيح التخزين
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
  static const String _languageKey = 'language';
  static const String _themeKey = 'theme';
  static const String _selectedVehicleKey = 'selected_vehicle';

  // ========== التهيئة ==========

  Future<void> init() async {
    if (_initialized) return;
    _initFuture ??= _createInstance();
    await _initFuture;
    _initialized = true;
    AppLogger.info('LocalStorageService initialized');
  }

  Future<void> _createInstance() async {
    _prefs = await SharedPreferencesWithCache.create(
      sharedPreferencesOptions: Platform.isAndroid
          ? const SharedPreferencesAsyncAndroidOptions(
              backend: SharedPreferencesAndroidBackendLibrary.SharedPreferences)
          : const SharedPreferencesOptions(),
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {
          _deviceIdKey, _serverUrlKey, _accuracyKey, _distanceKey,
          _intervalKey, _angleKey, _heartbeatKey, _bufferKey,
          _wakelockKey, _stopDetectionKey, _preferPlatformProvidersKey,
          _languageKey, _themeKey, _selectedVehicleKey,
        },
      ),
    );

    // إصلاح Android
    if (Platform.isAndroid) {
      for (final key in {_intervalKey, _distanceKey, _angleKey, _heartbeatKey}) {
        if (_prefs.get(key) is String) {
          await _prefs.setInt(key, int.tryParse(_prefs.getString(key) ?? '') ?? 0);
        }
      }
    }

    await _setDefaults();
  }

  Future<void> _setDefaults() async {
    // معرف جهاز عشوائي إذا لم يكن موجوداً
    if (_prefs.getString(_deviceIdKey) == null) {
      final randomId = (Random().nextInt(90000000) + 10000000).toString();
      await _prefs.setString(_deviceIdKey, randomId);
      AppLogger.info('Generated new device ID: $randomId');
    }

    // مسح Demo fallback - الخادم الافتراضي يجب أن يكون demo.traccar.org
    final currentUrl = _prefs.getString(_serverUrlKey);
    if (currentUrl == null || currentUrl.contains('mock-traccar-server') || currentUrl.contains('api.goldenfeather.com')) {
      await _prefs.setString(_serverUrlKey, 'https://demo.traccar.org');
    }
    await _setIfNull(_accuracyKey, 'medium');
    await _setIfNull(_intervalKey, AppConstants.defaultIntervalSeconds);
    await _setIfNull(_distanceKey, AppConstants.defaultDistanceMeters.toInt());
    await _setIfNull(_bufferKey, true);
    await _setIfNull(_stopDetectionKey, true);
    await _setIfNull(_wakelockKey, false);
    await _setIfNull(_preferPlatformProvidersKey, false);
  }

  Future<void> _setIfNull<T>(String key, T value) async {
    if (!_prefs.containsKey(key)) {
      if (T == String) {
        await _prefs.setString(key, value as String);
      } else if (T == int) {
        await _prefs.setInt(key, value as int);
      } else if (T == bool) {
        await _prefs.setBool(key, value as bool);
      }
    }
  }

  // ========== Getters ==========

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
  Future<String?> get password => _secureStorage.read(key: 'password');
  String get language => _prefs.getString(_languageKey) ?? 'ar';
  String get theme => _prefs.getString(_themeKey) ?? 'system';

  Future<bool> get hasPassword async {
    final pass = await password;
    return pass != null && pass.isNotEmpty;
  }

  // ========== Setters ==========

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
  Future<void> setLanguage(String value) => _prefs.setString(_languageKey, value);
  Future<void> setTheme(String value) => _prefs.setString(_themeKey, value);

  Future<void> setPassword(String value) async {
    if (value.isNotEmpty) {
      await _secureStorage.write(key: 'password', value: value);
    } else {
      await _secureStorage.delete(key: 'password');
    }
  }

  Future<void> removePassword() => _secureStorage.delete(key: 'password');

  // ========== إعدادات التتبع ==========

  /// بناء كائن إعدادات التتبع (متوافق مع Traccar)
  Config buildTrackingConfig() {
    return Config(
      serverUrl: serverUrl,
      deviceId: deviceId,
      location: LocationConfig(
        accuracy: switch (accuracy) {
          'highest' => Accuracy.highest,
          'high' => Accuracy.high,
          'low' => Accuracy.low,
          _ => Accuracy.medium,
        },
        distanceMeters: distance,
        intervalSeconds: interval,
        angleDegrees: angle,
        heartbeatIntervalSeconds: heartbeat,
        stopDetection: stopDetection,
      ),
      wakeLock: wakelock,
      buffer: buffer,
      preferPlatformProviders: preferPlatformProviders,
    );
  }

  /// تطبيق الإعدادات من رابط
  Future<void> applyFromUri(Uri uri) async {
    final params = uri.queryParameters;

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      await setServerUrl('${uri.origin}${uri.path}');
    } else {
      final url = params['url'];
      if (url != null) await setServerUrl(url);
    }

    // تطبيق المعاملات
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

  // ========== تخزين المركبة ==========

  String? get selectedVehicleId {
    return _prefs.getString(_selectedVehicleKey);
  }

  Future<void> saveSelectedVehicleId(String id) async {
    await _prefs.setString(_selectedVehicleKey, id);
  }

  Future<void> clearSelectedVehicle() async {
    await _prefs.remove(_selectedVehicleKey);
  }

  /// مسح جميع البيانات
  Future<void> clearAll() async {
    await _prefs.clear();
    await _setDefaults();
  }
}

/// مزود خدمة التخزين المحلي
final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});



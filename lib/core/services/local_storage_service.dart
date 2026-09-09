import 'dart:io';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

import 'auth_storage_service.dart';
import 'tracking_config_storage_service.dart';
import '../config/server_config_provider.dart';
import 'user_preferences_storage_service.dart';

/// خدمة التخزين المحلي - تعمل كواجهة (Facade) للخدمات الجديدة
class LocalStorageService implements ServerConfigProvider {
  static Future<void>? _initFuture;
  static late SharedPreferencesWithCache _prefs;
  bool _initialized = false;

  late final AuthStorageService _authStorage;
  late final TrackingConfigStorageService _trackingStorage;
  late final UserPreferencesStorageService _preferencesStorage;

  SharedPreferencesWithCache get prefs => _prefs;

  // ========== التهيئة ==========

  Future<void> init() async {
    if (_initialized) return;
    _initFuture ??= _createInstance();
    await _initFuture;

    _authStorage = AuthStorageService();
    _trackingStorage = TrackingConfigStorageService(_prefs);
    _preferencesStorage = UserPreferencesStorageService(_prefs);

    _initialized = true;
    AppLogger.info('LocalStorageService initialized (Facade)');
  }

  Future<void> _createInstance() async {
    _prefs = await SharedPreferencesWithCache.create(
      sharedPreferencesOptions: Platform.isAndroid
          ? const SharedPreferencesAsyncAndroidOptions(
              backend: SharedPreferencesAndroidBackendLibrary.SharedPreferences)
          : const SharedPreferencesOptions(),
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {
          'id',
          'url',
          'accuracy',
          'distance',
          'interval',
          'angle',
          'heartbeat',
          'buffer',
          'wakelock',
          'stop_detection',
          'prefer_platform_providers',
          'language',
          'theme',
          'selected_vehicle',
          'current_duty_status',
          'stationary_since',
          'backend_type',
          'cycle_rule',
          'cargo_type',
          'enable_30min_break',
          'enable_short_haul_16h',
          'enable_pc',
          'enable_ym',
        },
      ),
    );

    // إصلاح Android
    if (Platform.isAndroid) {
      for (final key in {'interval', 'distance', 'angle', 'heartbeat'}) {
        if (_prefs.get(key) is String) {
          await _prefs.setInt(
              key, int.tryParse(_prefs.getString(key) ?? '') ?? 0);
        }
      }
    }

    await _setDefaults();
  }

  Future<void> _setDefaults() async {
    // معرف جهاز عشوائي إذا لم يكن موجوداً
    if (_prefs.getString('id') == null) {
      final randomId = (Random().nextInt(90000000) + 10000000).toString();
      await _prefs.setString('id', randomId);
      AppLogger.info('Generated new device ID: $randomId');
    }

    // مسح Demo fallback - الخادم الافتراضي يجب أن يكون demo3.traccar.org
    final currentUrl = _prefs.getString('url');
    if (currentUrl == null ||
        currentUrl.contains('mock-traccar-server') ||
        currentUrl.contains('api.goldenfeather.com') ||
        currentUrl == 'https://demo.traccar.org') {
      await _prefs.setString('url', 'https://demo3.traccar.org');
    }
    await _setIfNull('accuracy', 'medium');
    await _setIfNull('interval', AppConstants.defaultIntervalSeconds);
    await _setIfNull('distance', AppConstants.defaultDistanceMeters.toInt());
    await _setIfNull('buffer', true);
    await _setIfNull('stop_detection', true);
    await _setIfNull('wakelock', false);
    await _setIfNull('prefer_platform_providers', false);
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

  @override
  String get serverUrl => _trackingStorage.serverUrl;
  @override
  String get backendType => _trackingStorage.backendType;

  String get deviceId => _trackingStorage.deviceId;
  String get accuracy => _trackingStorage.accuracy;
  int get distance => _trackingStorage.distance;
  int get interval => _trackingStorage.interval;
  int get angle => _trackingStorage.angle;
  int get heartbeat => _trackingStorage.heartbeat;
  bool get buffer => _trackingStorage.buffer;
  bool get wakelock => _trackingStorage.wakelock;
  bool get stopDetection => _trackingStorage.stopDetection;
  bool get preferPlatformProviders => _trackingStorage.preferPlatformProviders;

  Future<String?> get password => _authStorage.password;
  Future<bool> get hasPassword => _authStorage.hasPassword;

  String get language => _preferencesStorage.language;
  String get theme => _preferencesStorage.theme;
  String get currentDutyStatus => _preferencesStorage.currentDutyStatus;
  String? get stationarySince => _preferencesStorage.stationarySince;
  String? get selectedVehicleId => _preferencesStorage.selectedVehicleId;

  // ========== Setters ==========

  Future<void> setDeviceId(String value) => _trackingStorage.setDeviceId(value);
  Future<void> setServerUrl(String value) =>
      _trackingStorage.setServerUrl(value);
  Future<void> setAccuracy(String value) => _trackingStorage.setAccuracy(value);
  Future<void> setDistance(int value) => _trackingStorage.setDistance(value);
  Future<void> setInterval(int value) => _trackingStorage.setInterval(value);
  Future<void> setAngle(int value) => _trackingStorage.setAngle(value);
  Future<void> setHeartbeat(int value) => _trackingStorage.setHeartbeat(value);
  Future<void> setBuffer(bool value) => _trackingStorage.setBuffer(value);
  Future<void> setWakelock(bool value) => _trackingStorage.setWakelock(value);
  Future<void> setStopDetection(bool value) =>
      _trackingStorage.setStopDetection(value);
  Future<void> setPreferPlatformProviders(bool value) =>
      _trackingStorage.setPreferPlatformProviders(value);
  Future<void> setBackendType(String value) =>
      _trackingStorage.setBackendType(value);

  Future<void> setLanguage(String value) =>
      _preferencesStorage.setLanguage(value);
  Future<void> setTheme(String value) => _preferencesStorage.setTheme(value);
  Future<void> setCurrentDutyStatus(String value) =>
      _preferencesStorage.setCurrentDutyStatus(value);
  Future<void> setStationarySince(String value) =>
      _preferencesStorage.setStationarySince(value);

  Future<void> setPassword(String value) => _authStorage.setPassword(value);
  Future<void> removePassword() => _authStorage.removePassword();

  // ========== إعدادات التتبع ==========

  Future<void> applyFromUri(Uri uri) => _trackingStorage.applyFromUri(uri);

  // ========== تخزين المركبة ==========

  Future<void> saveSelectedVehicleId(String id) =>
      _preferencesStorage.saveSelectedVehicleId(id);
  Future<void> clearSelectedVehicle() =>
      _preferencesStorage.clearSelectedVehicle();

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

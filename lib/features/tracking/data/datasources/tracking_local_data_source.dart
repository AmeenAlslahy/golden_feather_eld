import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/local_storage_service.dart';
import '../models/location_model.dart';

/// مصدر بيانات التتبع المحلي
abstract class TrackingLocalDataSource {
  /// حفظ آخر موقع معروف
  Future<void> saveLastLocation(LocationModel location);

  /// الحصول على آخر موقع معروف
  Future<LocationModel?> getLastLocation();

  /// حفظ سجلات التتبع
  Future<void> saveLogs(List<String> logs);

  /// الحصول على سجلات التتبع المحفوظة
  Future<List<String>> getLogs();

  /// مسح السجلات
  Future<void> clearLogs();
}

/// تنفيذ مصدر بيانات التتبع المحلي
class TrackingLocalDataSourceImpl implements TrackingLocalDataSource {
  // ignore: unused_field
  final LocalStorageService _storage;

  TrackingLocalDataSourceImpl(this._storage);

  static const String _lastLocationKey = 'last_location';
  static const String _trackingLogsKey = 'tracking_logs';

  @override
  Future<void> saveLastLocation(LocationModel location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLocationKey, jsonEncode(location.toJson()));
  }

  @override
  Future<LocationModel?> getLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_lastLocationKey);
    if (data == null) return null;
    try {
      return LocationModel.fromJson(jsonDecode(data));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveLogs(List<String> logs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_trackingLogsKey, logs);
  }

  @override
  Future<List<String>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_trackingLogsKey) ?? [];
  }

  @override
  Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_trackingLogsKey);
  }
}




import 'dart:convert';

import '../../../../core/services/local_storage_service.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/current_codriver.dart';
import '../../domain/entities/codriver.dart';

abstract class CoDriverLocalCache {
  Future<void> saveAvailableDrivers(List<CoDriver> drivers);
  List<CoDriver>? loadAvailableDrivers();

  Future<void> saveCurrentCoDriver(CurrentCoDriverRead current);
  CurrentCoDriverRead? loadCurrentCoDriver();

  Future<void> clear();
}

class PrefsCoDriverLocalCache implements CoDriverLocalCache {
  final LocalStorageService _storage;

  static const String _driversKey = 'codriver_list_cache';
  static const String _currentKey = 'codriver_current_cache';

  PrefsCoDriverLocalCache(this._storage);

  @override
  Future<void> saveAvailableDrivers(List<CoDriver> drivers) async {
    try {
      final list = drivers
          .map((d) => {
                'id': d.id,
                'name': d.name,
                if (d.licenseNumber != null) 'licenseNumber': d.licenseNumber,
              })
          .toList();
      await _storage.prefs.setString(_driversKey, jsonEncode(list));
    } catch (e) {
      AppLogger.warning('CoDriverLocalCache.saveAvailableDrivers failed: $e');
    }
  }

  @override
  List<CoDriver>? loadAvailableDrivers() {
    try {
      final raw = _storage.prefs.getString(_driversKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map((item) => CoDriver(
                id: item['id']?.toString() ?? '',
                name: item['name']?.toString() ?? 'Unknown',
                licenseNumber: item['licenseNumber']?.toString(),
              ))
          .toList();
    } catch (e) {
      AppLogger.warning('CoDriverLocalCache.loadAvailableDrivers failed: $e');
      return null;
    }
  }

  @override
  Future<void> saveCurrentCoDriver(CurrentCoDriverRead current) async {
    try {
      final map = {
        'coDriverId': current.coDriverId,
        'coDriverName': current.name,
        'name': current.name,
        'teamDrivingActive': current.teamDrivingActive,
      };
      await _storage.prefs.setString(_currentKey, jsonEncode(map));
    } catch (e) {
      AppLogger.warning('CoDriverLocalCache.saveCurrentCoDriver failed: $e');
    }
  }

  @override
  CurrentCoDriverRead? loadCurrentCoDriver() {
    try {
      final raw = _storage.prefs.getString(_currentKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      return parseCurrentCoDriver(decoded);
    } catch (e) {
      AppLogger.warning('CoDriverLocalCache.loadCurrentCoDriver failed: $e');
      return null;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.prefs.remove(_driversKey);
      await _storage.prefs.remove(_currentKey);
    } catch (e) {
      AppLogger.warning('CoDriverLocalCache.clear failed: $e');
    }
  }
}

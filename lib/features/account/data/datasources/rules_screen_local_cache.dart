import 'dart:convert';

import '../../../../core/services/local_storage_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../application/models/rules_screen_model.dart';

abstract class RulesScreenLocalCache {
  Future<void> saveRulesScreen(RulesScreenModel model, {DriverId? driverId});
  RulesScreenModel? loadRulesScreen({DriverId? driverId});
  Future<void> clear({DriverId? driverId});
}

class PrefsRulesScreenLocalCache implements RulesScreenLocalCache {
  final LocalStorageService _storage;

  PrefsRulesScreenLocalCache(this._storage);

  static String _keyFor(DriverId? driverId) {
    if (driverId != null) {
      return 'rules_screen_cache_${driverId.value}';
    }
    return 'rules_screen_cache';
  }

  @override
  Future<void> saveRulesScreen(
    RulesScreenModel model, {
    DriverId? driverId,
  }) async {
    try {
      final key = _keyFor(driverId);
      await _storage.prefs.setString(key, jsonEncode(model.toJson()));
    } catch (e) {
      AppLogger.warning('RulesScreenLocalCache.saveRulesScreen failed: $e');
    }
  }

  @override
  RulesScreenModel? loadRulesScreen({DriverId? driverId}) {
    try {
      final key = _keyFor(driverId);
      final raw = _storage.prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return RulesScreenModel.fromJson(decoded);
    } catch (e) {
      AppLogger.warning('RulesScreenLocalCache.loadRulesScreen failed: $e');
      return null;
    }
  }

  @override
  Future<void> clear({DriverId? driverId}) async {
    try {
      final key = _keyFor(driverId);
      await _storage.prefs.remove(key);
    } catch (e) {
      AppLogger.warning('RulesScreenLocalCache.clear failed: $e');
    }
  }
}

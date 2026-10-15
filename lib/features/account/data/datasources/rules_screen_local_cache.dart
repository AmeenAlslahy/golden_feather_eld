import 'dart:convert';

import '../../../../core/services/local_storage_service.dart';
import '../../../../core/utils/logger.dart';
import '../../application/models/rules_screen_model.dart';

abstract class RulesScreenLocalCache {
  Future<void> saveRulesScreen(RulesScreenModel model);
  RulesScreenModel? loadRulesScreen();
  Future<void> clear();
}

class PrefsRulesScreenLocalCache implements RulesScreenLocalCache {
  final LocalStorageService _storage;
  static const String _key = 'rules_screen_cache';

  PrefsRulesScreenLocalCache(this._storage);

  @override
  Future<void> saveRulesScreen(RulesScreenModel model) async {
    try {
      await _storage.prefs.setString(_key, jsonEncode(model.toJson()));
    } catch (e) {
      AppLogger.warning('RulesScreenLocalCache.saveRulesScreen failed: $e');
    }
  }

  @override
  RulesScreenModel? loadRulesScreen() {
    try {
      final raw = _storage.prefs.getString(_key);
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
  Future<void> clear() async {
    try {
      await _storage.prefs.remove(_key);
    } catch (e) {
      AppLogger.warning('RulesScreenLocalCache.clear failed: $e');
    }
  }
}

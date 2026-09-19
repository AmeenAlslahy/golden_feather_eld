import 'package:shared_preferences/shared_preferences.dart';

import '../ports/key_value_port.dart';

/// [KeyValuePort] implementation backed by `SharedPreferences`.
///
/// **Note:** Uses the legacy `SharedPreferences.getInstance()` API
/// (not `SharedPreferencesWithCache`). This keeps testing simple and
/// compatible with `setMockInitialValues`.
class SharedPreferencesAdapter implements KeyValuePort {
  final SharedPreferences _prefs;

  SharedPreferencesAdapter._(this._prefs);

  /// Creates an adapter by awaiting `SharedPreferences.getInstance()`.
  ///
  /// Call once during app bootstrap and inject the instance.
  static Future<SharedPreferencesAdapter> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesAdapter._(prefs);
  }

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  int? getInt(String key) => _prefs.getInt(key);

  @override
  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  @override
  bool? getBool(String key) => _prefs.getBool(key);

  @override
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  @override
  double? getDouble(String key) => _prefs.getDouble(key);

  @override
  Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  @override
  bool containsKey(String key) => _prefs.containsKey(key);

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}

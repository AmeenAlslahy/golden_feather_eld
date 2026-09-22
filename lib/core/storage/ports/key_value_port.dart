/// Port for non-sensitive key-value storage.
///
/// Backed by `SharedPreferences` in production.
///
/// **Rule:** Never store tokens, passwords, or PII here — use
/// `SecureStoragePort`.
abstract interface class KeyValuePort {
  String? getString(String key);
  Future<void> setString(String key, String value);

  int? getInt(String key);
  Future<void> setInt(String key, int value);

  bool? getBool(String key);
  // ignore: avoid_positional_boolean_parameters
  Future<void> setBool(String key, bool value);

  double? getDouble(String key);
  Future<void> setDouble(String key, double value);

  bool containsKey(String key);

  Future<void> remove(String key);
  Future<void> clear();
}

/// Port for secure storage.
///
/// Implementations encrypt data at rest (e.g. Keychain, Keystore).
///
/// **Rule:** Never store secrets in `KeyValuePort` — only in
/// `SecureStoragePort`.
abstract interface class SecureStoragePort {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  Future<bool> containsKey(String key);

  Future<void> deleteAll();
}

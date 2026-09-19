import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../ports/secure_storage_port.dart';

/// [SecureStoragePort] implementation backed by
/// `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences
/// on Android).
class FlutterSecureStorageAdapter implements SecureStoragePort {
  final FlutterSecureStorage _storage;

  const FlutterSecureStorageAdapter([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<bool> containsKey(String key) => _storage.containsKey(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}

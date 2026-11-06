import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../utils/logger.dart';
import '../ports/secure_storage_port.dart';

/// [SecureStoragePort] implementation backed by
/// `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences
/// on Android) with graceful memory fallback for platform Keystore errors.
class FlutterSecureStorageAdapter implements SecureStoragePort {
  final FlutterSecureStorage _storage;
  final Map<String, String> _memoryFallback = {};

  FlutterSecureStorageAdapter([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value != null) {
        _memoryFallback[key] = value;
      }
      return value ?? _memoryFallback[key];
    } catch (e, st) {
      AppLogger.error(
        'SecureStorage read failed for key "$key", falling back to memory without wiping data',
        e,
        st,
      );
      return _memoryFallback[key];
    }
  }

  @override
  Future<void> write(String key, String value) async {
    _memoryFallback[key] = value;
    try {
      await _storage.write(key: key, value: value);
    } catch (e, st) {
      AppLogger.error(
        'SecureStorage write failed for key "$key", safely kept in process memory',
        e,
        st,
      );
    }
  }

  @override
  Future<void> delete(String key) async {
    _memoryFallback.remove(key);
    try {
      await _storage.delete(key: key);
    } catch (e) {
      AppLogger.warning('SecureStorage delete failed for key "$key": $e');
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      final exists = await _storage.containsKey(key: key);
      return exists || _memoryFallback.containsKey(key);
    } catch (_) {
      return _memoryFallback.containsKey(key);
    }
  }

  @override
  Future<void> deleteAll() async {
    _memoryFallback.clear();
    try {
      await _storage.deleteAll();
    } catch (e) {
      AppLogger.warning('SecureStorage deleteAll failed: $e');
    }
  }
}

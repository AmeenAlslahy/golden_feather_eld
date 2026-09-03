import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthStorageService {
  final FlutterSecureStorage _secureStorage;

  AuthStorageService([this._secureStorage = const FlutterSecureStorage()]);

  Future<String?> get password => _secureStorage.read(key: 'password');

  Future<bool> get hasPassword async {
    final pass = await password;
    return pass != null && pass.isNotEmpty;
  }

  Future<void> setPassword(String value) async {
    if (value.isNotEmpty) {
      await _secureStorage.write(key: 'password', value: value);
    } else {
      await _secureStorage.delete(key: 'password');
    }
  }

  Future<void> removePassword() => _secureStorage.delete(key: 'password');
}

final authStorageProvider = Provider<AuthStorageService>((ref) {
  return AuthStorageService();
});

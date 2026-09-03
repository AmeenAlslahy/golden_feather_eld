import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_storage_service.dart';

/// خدمة حماية كلمة المرور - طبقة الـ Business Logic
class PasswordService {
  final LocalStorageService _storage;

  PasswordService(this._storage);

  /// التحقق من مطابقة كلمة المرور المدخلة مع المخزنة
  Future<bool> verifyPassword(String input) async {
    final storedPassword = await _storage.password;
    if (storedPassword == null || storedPassword.isEmpty) {
      return true;
    }
    return storedPassword == input;
  }

  /// تعيين كلمة المرور
  Future<void> setPassword(String password) async {
    await _storage.setPassword(password);
  }

  /// إزالة كلمة المرور
  Future<void> removePassword() async {
    await _storage.removePassword();
  }

  /// هل توجد كلمة مرور
  Future<bool> get hasPassword => _storage.hasPassword;
}

/// مزود خدمة كلمة المرور
final passwordServiceProvider = Provider<PasswordService>((ref) {
  final storage = ref.watch(localStorageProvider);
  return PasswordService(storage);
});

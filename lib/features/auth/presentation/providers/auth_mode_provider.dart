import 'package:flutter_riverpod/flutter_riverpod.dart';

/// أوضاع شاشة المصادقة
///
/// لا يوجد وضع تسجيل حساب جديد: الحسابات تُنشأ من مدير الأسطول فقط (SRS §1).
enum AuthMode {
  login,
  forgotPassword,
}

/// مزود وضع المصادقة
final authModeProvider = StateProvider<AuthMode>((ref) {
  return AuthMode.login;
});

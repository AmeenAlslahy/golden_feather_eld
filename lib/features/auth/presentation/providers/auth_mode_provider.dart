import 'package:flutter_riverpod/flutter_riverpod.dart';

/// أوضاع شاشة المصادقة
enum AuthMode {
  login,
  register,
  forgotPassword,
}

/// مزود وضع المصادقة
final authModeProvider = StateProvider<AuthMode>((ref) {
  return AuthMode.login;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// حالة نموذج تسجيل الدخول
class LoginFormState {
  final bool obscurePassword;

  const LoginFormState({
    this.obscurePassword = true,
  });

  LoginFormState copyWith({
    bool? obscurePassword,
  }) {
    return LoginFormState(
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }
}

/// مزود حالة نموذج تسجيل الدخول
final loginFormProvider =
    StateNotifierProvider<LoginFormNotifier, LoginFormState>((ref) {
  return LoginFormNotifier();
});

class LoginFormNotifier extends StateNotifier<LoginFormState> {
  LoginFormNotifier() : super(const LoginFormState());

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

}

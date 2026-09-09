import 'package:flutter_riverpod/flutter_riverpod.dart';

/// حالة نموذج تسجيل الدخول
class LoginFormState {
  final bool obscurePassword;
  final bool showAdvanced;

  const LoginFormState({
    this.obscurePassword = true,
    this.showAdvanced = false,
  });

  LoginFormState copyWith({
    bool? obscurePassword,
    bool? showAdvanced,
  }) {
    return LoginFormState(
      obscurePassword: obscurePassword ?? this.obscurePassword,
      showAdvanced: showAdvanced ?? this.showAdvanced,
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

  void toggleAdvanced() {
    state = state.copyWith(showAdvanced: !state.showAdvanced);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_providers.dart';

/// حالة المصادقة
enum AuthStatus {
  initial, // لم يتم التحقق بعد
  authenticated, // مسجل الدخول
  offline, // جلسة محلية موجودة لكن غير متحقق منها بسبب انقطاع الشبكة
  unauthenticated, // غير مسجل
  loading, // جاري التحميل
  error, // خطأ
}

/// حالة المصادقة
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final String? arabicErrorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.arabicErrorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    String? arabicErrorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      arabicErrorMessage: arabicErrorMessage,
    );
  }

  bool get isAuthenticated =>
      (status == AuthStatus.authenticated || status == AuthStatus.offline) &&
      user != null;
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(traccarAuthRepositoryProvider);
  return AuthNotifier(
    repository: repository,
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier({
    required AuthRepository repository,
  })  : _repository = repository,
        super(const AuthState());

  /// التحقق من حالة المصادقة عند بدء التطبيق
  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final sessionResult = await _repository.checkAndRestoreSession();

      sessionResult.match((failure) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }, (user) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
      });
    } catch (e) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// تسجيل الدخول
  Future<bool> login({
    required String username,
    required String password,
    String? serverUrl,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    if (username.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'البريد الإلكتروني مطلوب',
        arabicErrorMessage: 'البريد الإلكتروني مطلوب',
      );
      AppLogger.error('Login failed: البريد الإلكتروني مطلوب');
      return false;
    }

    if (password.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'كلمة المرور مطلوبة',
        arabicErrorMessage: 'كلمة المرور مطلوبة',
      );
      AppLogger.error('Login failed: كلمة المرور مطلوبة');
      return false;
    }

    final result = await _repository.login(
      email: username,
      password: password,
    );

    return result.match(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
          arabicErrorMessage: failure.arabicMessage,
        );
        AppLogger.error('Login failed: ${failure.message}');
        return false;
      },
      (user) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
        AppLogger.info('Login successful: ${user.fullName}');
        return true;
      },
    );
  }

  /// إنشاء حساب جديد
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _repository.register(
      name: name,
      email: email,
      password: password,
    );

    return result.match(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
          arabicErrorMessage: failure.arabicMessage,
        );
        AppLogger.error('Registration failed: ${failure.message}');
        return false;
      },
      (user) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
        AppLogger.info('Registration successful: ${user.fullName}');
        return true;
      },
    );
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// التحقق من كلمة المرور المحلية (موقوف)
  Future<bool> verifyLocalPassword(String password) async {
    return true; // Stub
  }

  /// مسح الخطأ
  void clearError() {
    state = state.copyWith(
      errorMessage: null,
      arabicErrorMessage: null,
    );
  }
}

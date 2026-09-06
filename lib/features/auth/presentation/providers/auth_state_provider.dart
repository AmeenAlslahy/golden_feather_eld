import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/error/failure.dart';
import 'package:golden_feather_eld/core/entities/user.dart';
import '../../domain/entities/value_objects/email.dart';
import '../../domain/entities/value_objects/login_identifier.dart';
import '../../domain/entities/value_objects/password.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
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
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      arabicErrorMessage: clearError
          ? null
          : (arabicErrorMessage ?? arabicErrorMessage),
    );
  }

  bool get isAuthenticated =>
      (status == AuthStatus.authenticated || status == AuthStatus.offline) &&
      user != null;
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(traccarAuthRepositoryProvider);
  return AuthNotifier(
    loginUseCase: LoginUseCase(repository),
    registerUseCase: RegisterUseCase(repository),
    checkAuthStatusUseCase: CheckAuthStatusUseCase(repository),
    logoutUseCase: LogoutUseCase(repository),
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final CheckAuthStatusUseCase _checkAuthStatusUseCase;
  final LogoutUseCase _logoutUseCase;

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required CheckAuthStatusUseCase checkAuthStatusUseCase,
    required LogoutUseCase logoutUseCase,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _checkAuthStatusUseCase = checkAuthStatusUseCase,
        _logoutUseCase = logoutUseCase,
        super(const AuthState());

  /// استخراج دالة مساعدة لمعالجة الأخطاء وتقليل التكرار
  void _setErrorState(Failure failure, String logPrefix) {
    state = state.copyWith(
      status: AuthStatus.error,
      errorMessage: failure.message,
      );
    AppLogger.error('$logPrefix: ${failure.message}');
  }

  /// التحقق من حالة المصادقة عند بدء التطبيق
  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final sessionResult = await _checkAuthStatusUseCase();

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
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final identifierObj = LoginIdentifier(username);
    final passwordObj = Password(password);

    final result = await _loginUseCase(
      identifier: identifierObj,
      password: passwordObj,
    );

    return result.match(
      (failure) {
        _setErrorState(failure, 'Login failed');
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
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final emailObj = Email(email);
    final passwordObj = Password(password);

    final result = await _registerUseCase(
      name: name,
      email: emailObj,
      password: passwordObj,
    );

    return result.match(
      (failure) {
        _setErrorState(failure, 'Registration failed');
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
    await _logoutUseCase();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// مسح الخطأ
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/error/failure.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import '../../domain/entities/value_objects/login_identifier.dart';
import '../../domain/entities/value_objects/password.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_providers.dart';
import '../../../../backend/providers/backend_network_providers.dart';

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
      arabicErrorMessage:
          clearError ? null : (arabicErrorMessage ?? arabicErrorMessage),
    );
  }

  bool get isAuthenticated =>
      (status == AuthStatus.authenticated || status == AuthStatus.offline) &&
      user != null;
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(traccarAuthRepositoryProvider);
  final notifier = AuthNotifier(
    loginUseCase: LoginUseCase(repository),
    checkAuthStatusUseCase: CheckAuthStatusUseCase(repository),
    logoutUseCase: LogoutUseCase(repository),
  );

  final unauthEventStream = ref.watch(unauthenticatedEventProvider).stream;
  final subscription = unauthEventStream.listen((_) {
    notifier.forceLogout();
  });
  
  ref.onDispose(() {
    subscription.cancel();
  });

  return notifier;
});

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final CheckAuthStatusUseCase _checkAuthStatusUseCase;
  final LogoutUseCase _logoutUseCase;

  int _operationId = 0;
  bool _isOperationInProgress = false;

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required CheckAuthStatusUseCase checkAuthStatusUseCase,
    required LogoutUseCase logoutUseCase,
  })  : _loginUseCase = loginUseCase,
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
    if (_isOperationInProgress) return;

    final currentOpId = ++_operationId;
    _isOperationInProgress = true;
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final sessionResult = await _checkAuthStatusUseCase();
      if (currentOpId != _operationId) return;

      sessionResult.match((failure) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }, (user) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
      });
    } catch (e) {
      if (currentOpId == _operationId) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } finally {
      if (currentOpId == _operationId) {
        _isOperationInProgress = false;
      }
    }
  }

  /// تسجيل الدخول
  Future<bool> login({
    required String username,
    required String password,
    String? serverUrl,
  }) async {
    if (_isOperationInProgress) return false;

    final currentOpId = ++_operationId;
    _isOperationInProgress = true;

    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final identifierObj = LoginIdentifier(username);
      final passwordObj = Password(password);

      final result = await _loginUseCase(
        identifier: identifierObj,
        password: passwordObj,
      );

      if (currentOpId != _operationId) return false;

      return await result.match(
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
    } finally {
      if (currentOpId == _operationId) {
        _isOperationInProgress = false;
      }
    }
  }

  /// تسجيل الخروج الإجباري (يطرد المستخدم فوراً ويمسح الجلسة)
  void forceLogout() {
    ++_operationId; // إلغاء أي عمليات معلقة
    _isOperationInProgress = false;
    state = const AuthState(status: AuthStatus.unauthenticated);
    _logoutUseCase(); // Fire and forget
  }

  /// تسجيل الخروج العادي
  Future<void> logout() async {
    if (_isOperationInProgress) return;

    final currentOpId = ++_operationId;
    _isOperationInProgress = true;
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      await _logoutUseCase();
    } finally {
      if (currentOpId == _operationId) {
        _isOperationInProgress = false;
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    }
  }

  /// مسح الخطأ
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

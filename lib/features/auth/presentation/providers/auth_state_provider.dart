import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/datasources/user_store.dart';
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

/// مزود حالة المصادقة القديم (للتوافق مع الـ UI)
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(traccarAuthRepositoryProvider);
  final userStore = ref.watch(userStoreProvider);
  return AuthNotifier(
    repository: repository,
    userStore: userStore,
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final UserStore _userStore;

  AuthNotifier({
    required AuthRepository repository,
    required UserStore userStore,
  })  : _repository = repository,
        _userStore = userStore,
        super(const AuthState());

  /// التحقق من حالة المصادقة عند بدء التطبيق
  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final sessionResult = await _repository.checkAndRestoreSession();

      sessionResult.match((failure) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }, (session) async {
        // محاولة استرجاع المستخدم من التخزين الآمن
        User? user = await _userStore.getUser();

        if (user == null) {
          // إذا لم يكن موجوداً، نقوم بإنشائه من الميتاداتا وحفظه
          final email = session.userMetadata['email'] ??
              session.userMetadata['name'] ??
              'unknown';
          user = User(
            id: session.userMetadata['id']?.toString() ?? '',
            fullName: session.userMetadata['name'] ?? email,
            email: email,
            username: email,
            role: UserRole.fieldWorker,
            createdAt: DateTime.now(),
          );
          await _userStore.saveUser(user);
        }

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
      (authSession) async {
        final user = User.fromJson(authSession.userMetadata);

        // حفظ بيانات المستخدم في التخزين المخصص
        await _userStore.saveUser(user);

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
      (authSession) async {
        final emailStr = authSession.userMetadata['email'] ??
            authSession.userMetadata['name'] ??
            email;
        final user = User(
          id: authSession.userMetadata['id']?.toString() ?? '',
          fullName: authSession.userMetadata['name'] ?? name,
          email: emailStr,
          username: emailStr,
          role: UserRole.fieldWorker,
          createdAt: DateTime.now(),
        );

        // حفظ بيانات المستخدم في التخزين المخصص
        await _userStore.saveUser(user);

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
    await _userStore.clearUser(); // مسح بيانات المستخدم من الـ Secure Storage
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

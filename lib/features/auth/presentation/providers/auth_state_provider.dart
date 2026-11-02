import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/session/owner_identity.dart';
import '../../../../core/session/session_epoch.dart';
import '../../../../core/utils/startup_profiler.dart';
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
///
/// P0 Stage 1 — حدود الجلسة: [sessionEpoch] لقطة من [SessionEpoch.current]
/// تُستخدم لإبطال الاستجابات المتأخرة، و[transitioning] بوابة تمنع عرض
/// بيانات مالك سابق أو بدء جلب مالك جديد قبل اكتمال الانتقال.
/// الـ epoch إشارة إبطال فقط وليس إثبات ملكية (الملكية لـ driverId).
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final String? arabicErrorMessage;

  /// جيل الجلسة لحظة إنتاج هذه الحالة.
  final int sessionEpoch;

  /// true أثناء انتقال غير مكتمل (logout/login جاريان).
  final bool transitioning;

  /// معرف فريد لكل login ناجح (للتدقيق فقط).
  final String? sessionId;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.arabicErrorMessage,
    this.sessionEpoch = 0,
    this.transitioning = false,
    this.sessionId,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    String? arabicErrorMessage,
    bool clearError = false,
    bool clearUser = false,
    int? sessionEpoch,
    bool? transitioning,
    String? sessionId,
    bool clearSessionId = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      // النسخة السابقة كانت `(arabicErrorMessage ?? arabicErrorMessage)` —
      // مرجع ذاتي يجعل الحقل لا يمكن تعيينه إطلاقًا.
      arabicErrorMessage: clearError
          ? null
          : (arabicErrorMessage ?? this.arabicErrorMessage),
      sessionEpoch: sessionEpoch ?? this.sessionEpoch,
      transitioning: transitioning ?? this.transitioning,
      sessionId: clearSessionId ? null : (sessionId ?? this.sessionId),
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
  final subscription = unauthEventStream.listen((requestEpoch) {
    // P0 Stage 1: 401 قديم من جلسة سابقة يجب ألا ينهي جلسة جديدة.
    // الـ interceptor يوسم كل طلب بالـ epoch الذي أنشأه؛ أي حدث أقدم
    // من الجيل الحالي يُتجاهل.
    if (requestEpoch != SessionEpoch.current) {
      AppLogger.warning(
        'Ignoring stale 401 from epoch $requestEpoch (current ${SessionEpoch.current})',
      );
      return;
    }
    notifier.forceLogout();
  });

  ref.onDispose(() {
    subscription.cancel();
  });

  // P0 2B-1 (مراجعة 2026-10-30) — تركيب هوية المالك للسياج من مصدرها
  // الموحّد. الإسناد هنا لا في backend_network_providers لكسر دائرة
  // الاستيراد (backend لا يستطيع استيراد features/auth لأن هذا الملف
  // يستورده). القراءة كسولة لحظة الإرسال عبر دالة top-level — لا إحالة
  // للمزود داخل المُهيّئ نفسه كي لا يرى المحلل دائرة إعلانية.
  OwnerIdentityBinding.install(() => _readCurrentOwnerDriverId(ref));

  return notifier;
});

/// قراءة هوية المالك لحظة الإرسال — معرفة كدالة top-level (لا داخل
/// مُهيّئ [authStateProvider]) لكسر الدائرة الإعلانية مع
/// [currentDriverIdProvider] الذي يراقب حالة المصادقة.
Future<int?> _readCurrentOwnerDriverId(Ref ref) async =>
    ref.read(currentDriverIdProvider);

/// جيل الجلسة الحالي — يُبطل العمليات غير المتزامنة القديمة.
/// يزيد فقط عند حدود الهوية (بدء logout، طرد إجباري، إبطال الجلسة
/// الحالية، login ناجح). لا يزيد عند تحديث الملف أو الترميم أو الفشل.
final sessionEpochProvider = Provider<int>((ref) {
  return ref.watch(authStateProvider).sessionEpoch;
});

/// true أثناء انتقال غير مكتمل بين الحسابات — الواجهات تعرض حيادياً.
final sessionTransitionProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).transitioning;
});

/// معرف السائق الفعلي في نظام ELD (المسجل في جدول eld_drivers) **مختوماً
/// بجيل الجلسة الذي اكتُشف فيه**. قد يختلف عن معرف مستخدم Traccar (جدول
/// users) — ومقارنة الفضاءين كانت تُسقط كل طلب ملزم بمالك في سياج
/// الإرسال (P0 2B-1 مراجعة 2026-10-30).
///
/// الختم بالجيل يجعل القيمة تموت مع الجلسة تلقائياً بلا مستمعات: قيمة
/// جيل قديم لا تُقرأ أبداً — كانت تبقى حية عبر تسجيل الخروج وتُورَّث
/// للحساب التالي حتى تحميل لوحته (تسريب هوية عبر السياج).
///
/// يُحدَّث عند بدء الجلسة (ربط الجهاز) أو استلام لوحة HOS أو اختيار السائق.
final activeDriverIdProvider = StateProvider<(int, int)?>((ref) => null);

/// مزود للوصول السريع إلى معرف السائق الحالي أو null إذا لم يكن مسجلاً.
///
/// **هذا هو فضاء الختم الموحّد للملكية**: ما يُختَم به الطلب عند بنائه
/// هو ما يُقارن به عند الإرسال (سياج AuthInterceptor وسياق الموزّع) —
/// لا يجوز أن يقرأ السياج فضاءً آخر (كان يقرأ مستخدم Traccar).
final currentDriverIdProvider = Provider<int?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (!authState.isAuthenticated || authState.user == null) {
    return null;
  }
  final stamped = ref.watch(activeDriverIdProvider);
  final activeId =
      (stamped != null &&
          stamped.$1 == SessionEpoch.current &&
          stamped.$2 > 0)
      ? stamped.$2
      : null;
  if (activeId != null) {
    return activeId;
  }
  if (authState.user!.isAdmin) {
    return null;
  }
  return int.tryParse(authState.user!.id);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final CheckAuthStatusUseCase _checkAuthStatusUseCase;
  final LogoutUseCase _logoutUseCase;

  int _operationId = 0;
  bool _isOperationInProgress = false;

  /// P0 Stage 1 — تسلسل عمليات التخزين: clear(A) المتأخر يجب ألا يمحو
  /// save(B). كل مسح/حفظ للجلسة يمر بهذه السلسلة بالترتيب.
  Future<void> _storageChain = Future<void>.value();

  Future<void> _runOrdered(Future<void> Function() op) {
    final run = _storageChain.then((_) => op());
    _storageChain = run.catchError((_) {});
    return run;
  }

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required CheckAuthStatusUseCase checkAuthStatusUseCase,
    required LogoutUseCase logoutUseCase,
  }) : _loginUseCase = loginUseCase,
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
  ///
  /// P0 Stage 1: استعادة الجلسة (متصلة أو أوفلاين) ليست حداً للهوية —
  /// لا تزيد الـ epoch. تُحافظ على الجيل الحالي في كل المخارج.
  Future<void> checkAuthStatus() async {
    if (_isOperationInProgress) return;

    final currentOpId = ++_operationId;
    _isOperationInProgress = true;
    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      transitioning: true,
    );

    try {
      // M0 — قياس إجمالي فحص المصادقة (قراءة محلية + تحقق شبكي عند الاتصال).
      StartupProfiler.mark('auth:check:start');
      final sessionResult = await _checkAuthStatusUseCase();
      StartupProfiler.mark('auth:check:end');
      if (currentOpId != _operationId) return;

      sessionResult.match(
        (failure) {
          state = AuthState(
            status: AuthStatus.unauthenticated,
            sessionEpoch: state.sessionEpoch,
          );
        },
        (user) {
          state = AuthState(
            status: AuthStatus.authenticated,
            user: user,
            sessionEpoch: state.sessionEpoch,
          );
        },
      );
    } catch (e) {
      if (currentOpId == _operationId) {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          sessionEpoch: state.sessionEpoch,
        );
      }
    } finally {
      if (currentOpId == _operationId) {
        _isOperationInProgress = false;
      }
    }
  }

  /// تسجيل الدخول
  ///
  /// P0 Stage 1: ينتظر استقرار مسح الجلسة السابقة قبل بدء المصادقة
  /// (يمنع save(B) ثم مسح متأخر). النجاح فقط يؤسس جيلاً جديداً بهوية B؛
  /// الفشل لا يمس الـ epoch ولا يعيد أي بيانات قديمة.
  Future<bool> login({
    required String username,
    required String password,
    String? serverUrl,
  }) async {
    if (_isOperationInProgress) return false;

    final currentOpId = ++_operationId;
    _isOperationInProgress = true;

    state = state.copyWith(
      status: AuthStatus.loading,
      clearError: true,
      clearUser: true,
      clearSessionId: true,
      transitioning: true,
    );

    try {
      // استقرار أي clear(A) معلق قبل إنشاء جلسة B.
      await _storageChain;
      if (currentOpId != _operationId) return false;

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
          if (currentOpId == _operationId) {
            state = state.copyWith(transitioning: false);
          }
          return false;
        },
        (user) {
          // حد هوية ناجح: جيل جديد + معرف جلسة جديد.
          final epoch = SessionEpoch.bump();
          state = AuthState(
            status: AuthStatus.authenticated,
            user: user,
            sessionEpoch: epoch,
            sessionId: 'sess_${epoch}_${user.id}',
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
  ///
  /// P0 Stage 1: حد هوية فوري — epoch جديد وحالة محايدة متزامنة أولاً،
  /// ثم المسح عبر السلسلة المرتبة (لا يمحو جلسة أحدث لاحقاً).
  ///
  /// P0 leak fix: idempotent — 401 مكرر أو قديم بعد خروج مكتمل لا يُعيد
  /// المسح ولا يرفع epoch عبثاً (login اللاحق يؤسس جيله بنفسه).
  void forceLogout() {
    if (state.status == AuthStatus.unauthenticated) {
      AppLogger.info('forceLogout ignored: already unauthenticated');
      return;
    }
    ++_operationId; // إلغاء أي عمليات معلقة
    _isOperationInProgress = false;
    final epoch = SessionEpoch.bump();
    state = AuthState(status: AuthStatus.unauthenticated, sessionEpoch: epoch);
    _runOrdered(() => _logoutUseCase());
  }

  /// تسجيل الخروج العادي
  ///
  /// P0 Stage 1: حد الهوية يبدأ متزامناً (epoch جديد + إسقاط المستخدم
  /// فوراً حتى لا تعرض الواجهات A أثناء شبكة logout)، والمسح مرتب.
  Future<void> logout() async {
    if (_isOperationInProgress) return;

    final currentOpId = ++_operationId;
    _isOperationInProgress = true;
    final epoch = SessionEpoch.bump();
    state = AuthState(
      status: AuthStatus.loading,
      sessionEpoch: epoch,
      transitioning: true,
    );

    try {
      await _runOrdered(() => _logoutUseCase());
    } finally {
      if (currentOpId == _operationId) {
        _isOperationInProgress = false;
        state = AuthState(
          status: AuthStatus.unauthenticated,
          sessionEpoch: epoch,
        );
      }
    }
  }

  /// مسح الخطأ
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

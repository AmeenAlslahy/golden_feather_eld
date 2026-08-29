import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/exception.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/local_storage_service.dart';
import '../entities/auth_session.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/auth_session_store.dart';

abstract class AuthRepository {
  /// تسجيل الدخول إلى الخادم
  Future<Either<Failure, AuthSession>> login({
    required String email,
    required String password,
  });

  /// إنشاء حساب جديد (وتسجيل الدخول به تلقائياً)
  Future<Either<Failure, AuthSession>> register({
    required String name,
    required String email,
    required String password,
  });

  /// التحقق من صلاحية الجلسة المحفوظة واستعادتها
  Future<Either<Failure, AuthSession>> checkAndRestoreSession();

  /// تسجيل الخروج وحذف الجلسة
  Future<Either<Failure, Unit>> logout();

  /// الحصول على الجلسة الحالية (بدون اتصال بالشبكة)
  Future<Either<Failure, AuthSession>> getCurrentSession();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthSessionStore _sessionStore;
  final LocalStorageService _localStorage;
  final NetworkInfo _networkInfo;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthSessionStore sessionStore,
    required LocalStorageService localStorage,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _sessionStore = sessionStore,
        _localStorage = localStorage,
        _networkInfo = networkInfo;

  String? _getServerUrl() {
    final url = _localStorage.serverUrl;
    if (url.isEmpty) return null;
    return url;
  }

  @override
  Future<Either<Failure, AuthSession>> login({
    required String email,
    required String password,
  }) async {
    final serverUrl = _getServerUrl();
    if (serverUrl == null) {
      return const Left(MissingConfigurationFailure());
    }

    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final session = await _remoteDataSource.login(
        email: email,
        password: password,
        serverUrl: serverUrl,
      );

      await _sessionStore.saveSession(session);
      return Right(session);
    } catch (e) {
      if (e is ServerException) {
        if (e.statusCode == 401) {
          return const Left(InvalidCredentialsFailure());
        }
        return Left(ServerFailure(message: e.message ?? 'فشل الاتصال بالخادم', statusCode: e.statusCode));
      }
      return const Left(ServerFailure(message: 'فشل تسجيل الدخول غير معروف'));
    }
  }

  @override
  Future<Either<Failure, AuthSession>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final serverUrl = _getServerUrl();
    if (serverUrl == null) {
      return const Left(MissingConfigurationFailure());
    }

    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await _remoteDataSource.register(
        name: name,
        email: email,
        password: password,
        serverUrl: serverUrl,
      );
      
      // الدخول التلقائي بعد إنشاء الحساب
      return login(email: email, password: password);
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.arabicMessage ?? e.message ?? 'فشل الاتصال بالخادم', statusCode: e.statusCode));
      }
      return const Left(ServerFailure(message: 'فشل إنشاء الحساب غير معروف'));
    }
  }

  @override
  Future<Either<Failure, AuthSession>> checkAndRestoreSession() async {
    final serverUrl = _getServerUrl();
    if (serverUrl == null) {
      await _sessionStore.clearSession(); // مسح الجلسة إن وجد خادم غير مهيأ
      return const Left(MissingConfigurationFailure());
    }

    final savedSession = await _sessionStore.getSession();
    if (savedSession == null) {
      return const Left(SessionMissingFailure());
    }

    // بناء origin للمقارنة
    late String currentOrigin;
    try {
      currentOrigin = Uri.parse(serverUrl).origin;
    } catch (_) {
      return const Left(InvalidConfigurationFailure());
    }

    if (!savedSession.belongsTo(currentOrigin)) {
      // الجلسة تخص خادماً آخر، يجب حذفها
      await _sessionStore.clearSession();
      return const Left(SessionMissingFailure(message: 'تغير الخادم، يرجى تسجيل الدخول مجدداً'));
    }

    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      // الشبكة مقطوعة، لا نستطيع التحقق. لكننا نرجع الجلسة كـ Failure محدد لنعرف أنه تعذر الفحص.
      // أو نرجع NetworkFailure كالمعتاد.
      return const Left(NetworkFailure(message: 'تعذر التحقق من الجلسة لانقطاع الشبكة'));
    }

    try {
      final validSession = await _remoteDataSource.validateSession(currentSession: savedSession);
      // تحديث الجلسة ببيانات المستخدم الأحدث
      await _sessionStore.saveSession(validSession);
      return Right(validSession);
    } catch (e) {
      if (e is ServerException && e.statusCode == 401) {
        await _sessionStore.clearSession();
        return const Left(AuthFailure(message: 'الجلسة انتهت، يرجى تسجيل الدخول'));
      }
      // فشل شبكي أو سيرفر، لا نحذف الجلسة هنا.
      return const Left(ServerFailure(message: 'فشل الخادم أثناء فحص الجلسة'));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    final savedSession = await _sessionStore.getSession();
    if (savedSession != null) {
      final isConnected = await _networkInfo.isConnected;
      if (isConnected) {
        // محاولة إنهاء الجلسة من الخادم
        await _remoteDataSource.logout(currentSession: savedSession);
      }
    }
    // مسح الجلسة المحلية في كل الأحوال
    await _sessionStore.clearSession();
    return const Right(unit);
  }

  @override
  Future<Either<Failure, AuthSession>> getCurrentSession() async {
    final savedSession = await _sessionStore.getSession();
    if (savedSession != null) {
      final serverUrl = _getServerUrl();
      if (serverUrl != null) {
        try {
          final currentOrigin = Uri.parse(serverUrl).origin;
          if (savedSession.belongsTo(currentOrigin)) {
            return Right(savedSession);
          }
        } catch (_) {}
      }
    }
    return const Left(SessionMissingFailure());
  }
}

import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/exception.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/config/server_config_provider.dart';

import '../entities/user.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/user_store.dart';
import '../../data/datasources/auth_session_store.dart';
import '../../../../core/utils/repository_helper.dart';

abstract class AuthRepository {
  /// تسجيل الدخول إلى الخادم
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  /// إنشاء حساب جديد (وتسجيل الدخول به تلقائياً)
  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String password,
  });

  /// التحقق من صلاحية الجلسة المحفوظة واستعادتها
  Future<Either<Failure, User>> checkAndRestoreSession();

  /// تسجيل الخروج وحذف الجلسة
  Future<Either<Failure, Unit>> logout();

  /// الحصول على الجلسة الحالية (بدون اتصال بالشبكة)
  Future<Either<Failure, User>> getCurrentSession();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthSessionStore _sessionStore;
  final UserStore _userStore;
  final ServerConfigProvider _configProvider;
  final NetworkInfo _networkInfo;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthSessionStore sessionStore,
    required UserStore userStore,
    required ServerConfigProvider configProvider,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _sessionStore = sessionStore,
        _userStore = userStore,
        _configProvider = configProvider,
        _networkInfo = networkInfo;

  String? _getServerUrl() {
    final url = _configProvider.serverUrl;
    if (url.isEmpty) return null;
    return url;
  }

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    final serverUrl = _getServerUrl();
    if (serverUrl == null) {
      return const Left(MissingConfigurationFailure());
    }

    return executeWithHandling(() async {
      final backendType = _configProvider.backendType;
      final session = await _remoteDataSource.login(
        email: email,
        password: password,
        serverUrl: serverUrl,
        backendType: backendType,
      );

      await _sessionStore.saveSession(session);

      final user =
          _createUserFromMetadata(session.userMetadata, defaultEmail: email);
      await _userStore.saveUser(user);

      return user;
    }, tag: 'Auth.login', checkNetworkFirst: true, networkInfo: _networkInfo);
  }

  @override
  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final serverUrl = _getServerUrl();
    if (serverUrl == null) {
      return const Left(MissingConfigurationFailure());
    }

    return executeWithHandling(() async {
      final backendType = _configProvider.backendType;
      await _remoteDataSource.register(
        name: name,
        email: email,
        password: password,
        serverUrl: serverUrl,
        backendType: backendType,
      );

      final loginResult = await login(email: email, password: password);
      return loginResult.fold(
          (failure) => throw ServerException(
              message: failure.message, arabicMessage: failure.arabicMessage),
          (user) => user);
    },
        tag: 'Auth.register',
        checkNetworkFirst: true,
        networkInfo: _networkInfo);
  }

  @override
  Future<Either<Failure, User>> checkAndRestoreSession() async {
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
      await _userStore.clearUser();
      return const Left(SessionMissingFailure(
          message: 'تغير الخادم، يرجى تسجيل الدخول مجدداً'));
    }

    final isConnected = _networkInfo.isConnected;
    if (!isConnected) {
      // الشبكة مقطوعة، لا نستطيع التحقق.
      final user = await _userStore.getUser();
      if (user != null) {
        return Right(user);
      }
      return const Left(
          NetworkFailure(message: 'تعذر التحقق من الجلسة لانقطاع الشبكة'));
    }

    final result = await executeWithHandling(() async {
      final backendType = _configProvider.backendType;
      final validSession = await _remoteDataSource.validateSession(
        currentSession: savedSession,
        backendType: backendType,
      );
      // تحديث الجلسة ببيانات المستخدم الأحدث
      await _sessionStore.saveSession(validSession);

      final user = _createUserFromMetadata(validSession.userMetadata);
      await _userStore.saveUser(user);

      return user;
    }, tag: 'Auth.checkSession');

    if (result.isLeft()) {
      final failure = result.getLeft().toNullable()!;
      if (failure is InvalidCredentialsFailure || failure is AuthFailure) {
        await _sessionStore.clearSession();
        return const Left(
            AuthFailure(message: 'الجلسة انتهت، يرجى تسجيل الدخول'));
      }
      return Left(failure);
    }

    return Right(result.getRight().toNullable()!);
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    final savedSession = await _sessionStore.getSession();
    if (savedSession != null) {
      await executeWithHandling(() async {
        final backendType = _configProvider.backendType;
        await _remoteDataSource.logout(
          currentSession: savedSession,
          backendType: backendType,
        );
        return unit;
      },
          tag: 'Auth.logout',
          checkNetworkFirst: true,
          networkInfo: _networkInfo);
    }
    // مسح الجلسة المحلية في كل الأحوال
    await _sessionStore.clearSession();
    await _userStore.clearUser();
    return const Right(unit);
  }

  @override
  Future<Either<Failure, User>> getCurrentSession() async {
    final savedSession = await _sessionStore.getSession();
    if (savedSession != null) {
      final serverUrl = _getServerUrl();
      if (serverUrl != null) {
        try {
          final currentOrigin = Uri.parse(serverUrl).origin;
          if (savedSession.belongsTo(currentOrigin)) {
            final user = await _userStore.getUser();
            if (user != null) {
              return Right(user);
            }
          }
        } catch (_) {}
      }
    }
    return const Left(SessionMissingFailure());
  }

  ///
  User _createUserFromMetadata(Map<String, dynamic> metadata,
      {String? defaultEmail}) {
    final email =
        metadata['email'] ?? metadata['name'] ?? defaultEmail ?? 'unknown';
    return User(
      id: metadata['id']?.toString() ?? '',
      fullName: metadata['name'] ?? email,
      email: email,
      username: email,
      role: UserRole.fieldWorker,
      createdAt: DateTime.now(),
    );
  }
}

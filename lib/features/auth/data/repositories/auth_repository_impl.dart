import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/exception.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/config/server_config_provider.dart';

import '../../domain/entities/user.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/user_store.dart';
import '../datasources/auth_session_store.dart';
import '../../../../core/utils/repository_helper.dart';

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

      final userModel = UserModel.fromMetadata(session.userMetadata, defaultEmail: email);
      await _userStore.saveUser(userModel); // UserStore must accept User or UserModel

      return userModel;
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
          (failure) => throw ServerException(message: failure.message),
          (user) => user,
      );
    },
        tag: 'Auth.register',
        checkNetworkFirst: true,
        networkInfo: _networkInfo);
  }

  // NOTE: This will be moved to CheckAuthStatusUseCase, but keeping it here temporarily to not break things until Step 1 is fully executed.
  @override
  Future<Either<Failure, User>> checkAndRestoreSession() async {
    final serverUrl = _getServerUrl();
    if (serverUrl == null) {
      await _clearLocalData();
      return const Left(MissingConfigurationFailure());
    }

    final savedSession = await _sessionStore.getSession();
    if (savedSession == null) {
      return const Left(SessionMissingFailure());
    }

    if (!_isValidOrigin(serverUrl, savedSession)) {
      await _clearLocalData();
      return const Left(SessionMissingFailure());
    }

    if (!_networkInfo.isConnected) {
      return await _handleOfflineSession();
    }

    return await _validateRemoteSession(savedSession);
  }

  Future<void> _clearLocalData() async {
    await _sessionStore.clearSession();
    await _userStore.clearUser();
  }

  bool _isValidOrigin(String serverUrl, AuthSession session) {
    try {
      final currentOrigin = Uri.parse(serverUrl).origin;
      return session.belongsTo(currentOrigin);
    } catch (_) {
      return false;
    }
  }

  Future<Either<Failure, User>> _handleOfflineSession() async {
    final user = await _userStore.getUser();
    if (user != null) {
      return Right(user);
    }
    return const Left(NetworkFailure());
  }

  Future<Either<Failure, User>> _validateRemoteSession(AuthSession savedSession) async {
    final result = await executeWithHandling(() async {
      final backendType = _configProvider.backendType;
      final validSession = await _remoteDataSource.validateSession(
        currentSession: savedSession,
        backendType: backendType,
      );
      await _sessionStore.saveSession(validSession);

      final userModel = UserModel.fromMetadata(validSession.userMetadata);
      await _userStore.saveUser(userModel);

      return userModel;
    }, tag: 'Auth.checkSession');

    if (result.isLeft()) {
      final failure = result.getLeft().toNullable()!;
      if (failure is InvalidCredentialsFailure || failure is AuthFailure) {
        await _clearLocalData();
        return const Left(AuthFailure());
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
}

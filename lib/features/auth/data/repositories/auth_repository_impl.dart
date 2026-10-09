import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_guard.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/config/server_config_provider.dart';

import 'package:golden_feather_eld/core/domain/entities/user.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../backend/contracts/auth_backend.dart';
import '../datasources/auth_local_data_source.dart';
import '../models/auth_session_dto.dart';
import 'package:golden_feather_eld/core/data/models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthBackend _authBackend;
  final AuthLocalDataSource _localDataSource;
  final ServerConfigProvider _configProvider;
  final NetworkInfo _networkInfo;

  AuthRepositoryImpl({
    required AuthBackend authBackend,
    required AuthLocalDataSource localDataSource,
    required ServerConfigProvider configProvider,
    required NetworkInfo networkInfo,
  })  : _authBackend = authBackend,
        _localDataSource = localDataSource,
        _configProvider = configProvider,
        _networkInfo = networkInfo;

  String? _getServerUrl() {
    final url = _configProvider.serverUrl;
    if (url.isEmpty) return null;
    return url;
  }

  @override
  Future<Either<Failure, User>> login({
    required String identifier,
    required String password,
  }) async {
    final serverUrl = _getServerUrl();
    if (serverUrl == null) return const Left(MissingConfigurationFailure());
    return guardedNetwork(_networkInfo, () async {
    final backendType = _configProvider.backendType;
    final result = await _authBackend.login(
      identifier: identifier,
      password: password,
      serverUrl: serverUrl,
      backendType: backendType,
    );

    return result.fold(
      (error) {
        if (error.code == 'unauthorized') return const Left(InvalidCredentialsFailure());
        return Left(ServerFailure(message: error.code));
      },
      (rawJson) async {
        final sessionDto = AuthSessionDto.create(
          serverOrigin: rawJson['serverOrigin'],
          sessionCredential: rawJson['credential'],
          userModel: UserModel.fromMetadata(rawJson['user'], defaultEmail: identifier),
        );

        await _localDataSource.saveSession(sessionDto.toEntity());
        await _localDataSource.saveUser(sessionDto.userModel);
        return Right(sessionDto.userModel);
      }
    );
    });
  }

  @override
  Future<Either<Failure, User>> checkAndRestoreSession() async {
    final serverUrl = _getServerUrl();
    if (serverUrl == null) {
      await _clearLocalData();
      return const Left(MissingConfigurationFailure());
    }

    final savedSession = await _localDataSource.getSession();
    if (savedSession == null) return const Left(SessionMissingFailure());

    if (!_isValidOrigin(serverUrl, savedSession)) {
      await _clearLocalData();
      return const Left(SessionMissingFailure());
    }

    return guardedNetwork(
      _networkInfo,
      () => _validateRemoteSession(savedSession),
      offline: _handleOfflineSession,
    );
  }

  Future<void> _clearLocalData() async {
    await _localDataSource.clearSession();
    await _localDataSource.clearUser();
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
    final user = await _localDataSource.getUser();
    if (user != null) return Right(user);
    return const Left(NetworkFailure());
  }

  Future<Either<Failure, User>> _validateRemoteSession(AuthSession savedSession) async {
    final backendType = _configProvider.backendType;
    final sessionDto = AuthSessionDto.fromEntity(savedSession);
    
    final result = await _authBackend.validateSession(
      serverOrigin: sessionDto.serverOrigin,
      sessionCredential: sessionDto.sessionCredential,
      backendType: backendType,
    );

    return result.fold(
      (error) async {
        if (error.code == 'unauthorized') {
          await _clearLocalData();
          return const Left(AuthFailure());
        }
        return Left(ServerFailure(message: error.code));
      },
      (rawJson) async {
        final validSessionDto = AuthSessionDto.create(
          serverOrigin: rawJson['serverOrigin'],
          sessionCredential: rawJson['credential'],
          userModel: UserModel.fromMetadata(rawJson['user']),
        );
        
        await _localDataSource.saveSession(validSessionDto.toEntity());
        await _localDataSource.saveUser(validSessionDto.userModel);
        return Right(validSessionDto.userModel);
      }
    );
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      final savedSession = await _localDataSource.getSession();
      if (savedSession != null && _networkInfo.isConnected) {
        final sessionDto = AuthSessionDto.fromEntity(savedSession);
        await _authBackend.logout(
          serverOrigin: sessionDto.serverOrigin,
          sessionCredential: sessionDto.sessionCredential,
          backendType: _configProvider.backendType,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.warning('Backend logout failed, proceeding with local clear', e, stackTrace);
    } finally {
      await _clearLocalData();
    }
    return const Right(unit);
  }

  @override
  Future<Either<Failure, User>> getCurrentSession() async {
    final savedSession = await _localDataSource.getSession();
    if (savedSession != null) {
      final serverUrl = _getServerUrl();
      if (serverUrl != null) {
        try {
          final currentOrigin = Uri.parse(serverUrl).origin;
          if (savedSession.belongsTo(currentOrigin)) {
            final user = await _localDataSource.getUser();
            if (user != null) {
              return Right(user);
            }
          }
        } catch (e, st) {
          AppLogger.warning(
            'AuthRepositoryImpl.getCurrentSession: saved session could not be '
            'validated against origin "$serverUrl" — treating as missing',
            e,
            st,
          );
        }
      }
    }
    return const Left(SessionMissingFailure());
  }
}

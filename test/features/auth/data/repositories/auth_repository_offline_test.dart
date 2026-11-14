import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/config/server_config_provider.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/session/auth_session.dart';
import 'package:golden_feather_eld/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:golden_feather_eld/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:golden_feather_eld/backend/contracts/auth_backend.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBackend extends Mock implements AuthBackend {}

class _MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class _MockServerConfig extends Mock implements ServerConfigProvider {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

const _origin = 'https://example.com';

final _user = User(
  id: '1',
  fullName: 'Test Driver',
  email: 'driver@example.com',
  username: 'driver',
  role: UserRole.fieldWorker,
  createdAt: DateTime.utc(2026, 1, 1),
);

void main() {
  late _MockAuthBackend backend;
  late _MockAuthLocalDataSource local;
  late _MockServerConfig config;
  late _MockNetworkInfo network;

  setUp(() {
    backend = _MockAuthBackend();
    local = _MockAuthLocalDataSource();
    config = _MockServerConfig();
    network = _MockNetworkInfo();

    when(() => config.serverUrl).thenReturn(_origin);
    when(() => config.backendType).thenReturn('eld');
    when(
      () => local.getSession(),
    ).thenAnswer(
      (_) async => AuthSession.create(
        serverOrigin: _origin,
        sessionCredential: 'session-1',
        user: _user,
      ),
    );
  });

  AuthRepositoryImpl repository() => AuthRepositoryImpl(
    authBackend: backend,
    localDataSource: local,
    configProvider: config,
    networkInfo: network,
  );

  test(
    'offline cold start never authenticates from a cached session',
    () async {
      when(() => network.isConnected).thenReturn(false);

      Failure? failure;
      final result = await repository().checkAndRestoreSession();
      result.fold((error) => failure = error, (_) => fail('must not login'));

      expect(failure, isA<NetworkFailure>());
      // The cached user must never be used as a substitute for a server check.
      verifyNever(() => local.getUser());
      // Keep the stored session: a later online launch may still validate it.
      verifyNever(() => local.clearSession());
    },
  );

  test(
    'offline login is refused before any backend call',
    () async {
      when(() => network.isConnected).thenReturn(false);

      Failure? failure;
      final result = await repository().login(
        identifier: 'driver',
        password: 'secret',
      );
      result.fold((error) => failure = error, (_) => fail('must not login'));

      expect(failure, isA<NetworkFailure>());
      verifyNever(
        () => backend.login(
          identifier: any(named: 'identifier'),
          password: any(named: 'password'),
          serverUrl: any(named: 'serverUrl'),
          backendType: any(named: 'backendType'),
        ),
      );
    },
  );
}

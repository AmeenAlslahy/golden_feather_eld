import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/http/interceptors/auth_interceptor.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/session/session_epoch.dart';
import 'package:golden_feather_eld/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:golden_feather_eld/core/session/auth_session.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// P0 Stage 1 corrections — real interceptor path (Dio → AuthInterceptor →
/// mock adapter → 401). The bus-level TEST-04 cannot catch a broken
/// request-stamping, so these scenarios go through the production path.
void main() {
  late Dio dio;
  late DioAdapter adapter;
  late _FakeAuthLocalDataSource localDataSource;
  late List<int> firedEpochs;

  setUp(() {
    SessionEpoch.resetForTests();
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    adapter = DioAdapter(dio: dio);
    localDataSource = _FakeAuthLocalDataSource();
    firedEpochs = [];
    dio.interceptors.add(
      AuthInterceptor(
        localDataSource: localDataSource,
        backendType: 'traccar',
        resolveCurrentOwnerDriverId: () async => null,
        onUnauthenticated: firedEpochs.add,
      ),
    );
  });

  test(
    'INT-01: 401 for a request created before the session change is ignored',
    () async {
      localDataSource.session = _session();
      adapter.onGet(
        '/eld/status',
        (server) => server.reply(401, {
          'code': 'UNAUTHORIZED',
        }, delay: const Duration(milliseconds: 300)),
      );

      // Request A is created (and epoch-stamped) while session A is current.
      final future = dio.get<void>('/eld/status');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        SessionEpoch.current,
        0,
        reason: 'request must be stamped at epoch 0',
      );

      // Session changes to B before A's 401 arrives.
      SessionEpoch.bump();

      await expectLater(future, throwsA(isA<DioException>()));
      expect(
        firedEpochs,
        isEmpty,
        reason: 'stale 401 must not terminate the new session',
      );
    },
  );

  test('INT-02: 401 for the current session still invalidates it', () async {
    localDataSource.session = _session();
    adapter.onGet(
      '/eld/status',
      (server) => server.reply(401, {'code': 'UNAUTHORIZED'}),
    );

    await expectLater(
      dio.get<void>('/eld/status'),
      throwsA(isA<DioException>()),
    );

    expect(firedEpochs, [SessionEpoch.current]);
  });

  test('INT-03: 401 on a sessionless request never fires logout', () async {
    localDataSource.session = null;
    adapter.onGet(
      '/eld/status',
      (server) => server.reply(401, {'code': 'UNAUTHORIZED'}),
    );

    // An unrelated authenticated session exists meanwhile.
    SessionEpoch.bump();

    await expectLater(
      dio.get<void>('/eld/status'),
      throwsA(isA<DioException>()),
    );

    expect(firedEpochs, isEmpty);
  });
}

AuthSession _session() {
  return AuthSession(
    serverOrigin: 'https://api.example.com',
    sessionCredential: 'ABC123',
    user: User(
      id: '101',
      username: 'driver',
      email: 'd@example.com',
      fullName: 'Driver',
      role: UserRole.fieldWorker,
      createdAt: DateTime.utc(2026, 1, 1),
    ),
    createdAt: DateTime.utc(2026, 10, 1),
  );
}

class _FakeAuthLocalDataSource implements AuthLocalDataSource {
  AuthSession? session;
  int _gen = 0;

  @override
  int get credentialGeneration => _gen;

  @override
  Future<void> saveSession(AuthSession session) async {
    this.session = session;
    _gen++;
  }

  @override
  Future<AuthSession?> getSession() async => session;

  @override
  Future<void> clearSession() async {
    session = null;
    _gen++;
  }

  @override
  Future<void> saveUser(User user) async {}

  @override
  Future<User?> getUser() async => session?.user;

  @override
  Future<void> clearUser() async {}
}

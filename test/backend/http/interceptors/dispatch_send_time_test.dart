import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/http/interceptors/auth_interceptor.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/network/api_client.dart';
import 'package:golden_feather_eld/core/network/api_config.dart';
import 'package:golden_feather_eld/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:golden_feather_eld/core/session/auth_session.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// P0 2B-1 — send-time ownership binding through the real stack:
/// ApiClient → Dio → AuthInterceptor → (mock) HTTP.
///
/// Proves a queue event fenced for owner A can never leave the device
/// under session B, even if the dispatcher-level check raced past a
/// session change: the interceptor rejects before any byte is sent.
User _user(String id) => User(
  id: id,
  username: 'driver$id',
  email: 'd$id@example.com',
  fullName: 'Driver $id',
  role: UserRole.fieldWorker,
  createdAt: DateTime.utc(2026, 1, 1),
);

AuthSession _session(String driverId) => AuthSession(
  serverOrigin: 'https://api.example.com',
  sessionCredential: 'CRED-$driverId',
  user: _user(driverId),
  createdAt: DateTime.utc(2026, 3, 1),
);

class _FakeAuthLocalDataSource implements AuthLocalDataSource {
  AuthSession? session;
  int gen = 0;

  @override
  int get credentialGeneration => gen;

  @override
  Future<void> saveSession(AuthSession s) async {
    session = s;
    gen++;
  }

  @override
  Future<AuthSession?> getSession() async => session;

  @override
  Future<void> clearSession() async {
    session = null;
    gen++;
  }

  @override
  Future<void> saveUser(User user) async {}

  @override
  Future<User?> getUser() async => session?.user;

  @override
  Future<void> clearUser() async {}
}

/// Cookies observed leaving the device, in request order (proves which
/// session — if any — actually authenticated each HTTP call).
final List<String?> sentCookies = [];

Future<ApiClient> _client(
  _FakeAuthLocalDataSource sessions,
  List<int> unauthEpochs,
) async {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.interceptors.add(
    AuthInterceptor(
      localDataSource: sessions,
      backendType: 'traccar',
      onUnauthenticated: unauthEpochs.add,
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        sentCookies.add(options.headers['Cookie']?.toString());
        handler.next(options);
      },
    ),
  );
  DioAdapter(dio: dio).onPost(
    '/eld/duty-status',
    (server) => server.reply(200, {'ok': true}),
    data: Matchers.any,
  );
  return ApiClient(
    config: const ApiConfig(baseUrl: 'https://api.example.com'),
    dio: dio,
  );
}

void main() {
  setUp(sentCookies.clear);

  test(
    'S1: matching owner sends with the owner session cookie, no logout',
    () async {
      final sessions = _FakeAuthLocalDataSource();
      final unauth = <int>[];
      await sessions.saveSession(_session('101'));
      final client = await _client(sessions, unauth);

      final result = await client.post<dynamic>(
        '/eld/duty-status',
        data: {'driverId': 101},
        expectedOwnerDriverId: 101,
      );

      expect(result.isRight(), isTrue);
      expect(sentCookies, [
        'JSESSIONID=CRED-101',
      ], reason: 'only the bound owner session authenticates the call');
      expect(unauth, isEmpty);
    },
  );

  test(
    'S2: session changed after fencing → rejected before HTTP, no logout',
    () async {
      final sessions = _FakeAuthLocalDataSource();
      final unauth = <int>[];
      await sessions.saveSession(_session('101'));
      final client = await _client(sessions, unauth);

      // Logout A + login B AFTER the fence passed owner=101.
      await sessions.clearSession();
      await sessions.saveSession(_session('202'));

      final result = await client.post<dynamic>(
        '/eld/duty-status',
        data: {'driverId': 101},
        expectedOwnerDriverId: 101,
      );

      AppError? failure;
      result.match((l) => failure = l, (_) => null);
      expect(
        failure,
        isA<OwnerMismatchError>(),
        reason: 'must surface as quarantine, not transport error',
      );
      expect(
        sentCookies,
        isEmpty,
        reason: 'rejected before any byte leaves the device',
      );
      expect(
        unauth,
        isEmpty,
        reason: 'ownership refusal must never trigger logout',
      );
    },
  );

  test('S3: no session at send time → rejected, never anonymous', () async {
    final sessions = _FakeAuthLocalDataSource();
    final unauth = <int>[];
    await sessions.saveSession(_session('101'));
    final client = await _client(sessions, unauth);
    await sessions.clearSession();

    final result = await client.post<dynamic>(
      '/eld/duty-status',
      data: {'driverId': 101},
      expectedOwnerDriverId: 101,
    );

    AppError? failure;
    result.match((l) => failure = l, (_) => null);
    expect(failure, isA<OwnerMismatchError>());
    expect(unauth, isEmpty);
  });

  test('S4: unbound requests keep legacy behavior', () async {
    final sessions = _FakeAuthLocalDataSource();
    final unauth = <int>[];
    await sessions.saveSession(_session('202'));
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.interceptors.add(
      AuthInterceptor(
        localDataSource: sessions,
        backendType: 'traccar',
        onUnauthenticated: unauth.add,
      ),
    );
    DioAdapter(
      dio: dio,
    ).onGet('/eld/dvir/catalog', (server) => server.reply(200, {'items': []}));
    final client = ApiClient(
      config: const ApiConfig(baseUrl: 'https://api.example.com'),
      dio: dio,
    );

    final result = await client.get<dynamic>('/eld/dvir/catalog');

    expect(result.isRight(), isTrue);
    expect(unauth, isEmpty);
  });
}

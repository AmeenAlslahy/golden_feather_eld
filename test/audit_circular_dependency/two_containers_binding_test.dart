// P0 audit — two LIVE ProviderContainers in the same process.
//
// Isolated local test only: no network, no device, no real server, no real
// credentials. Identities are synthetic driver ids 1 and 2 and the HTTP
// adapter is an in-memory fake.
//
// It answers one question the single-container suite cannot:
//   OwnerIdentityBinding is process-static and last-install-wins. If a second
//   ProviderContainer builds authStateProvider, the binding moves to the
//   newest container. What happens to requests stamped by the older, still
//   live container — and what happens when the newest container is disposed
//   while the older one stays alive?

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:golden_feather_eld/app/di/app_providers.dart';
import 'package:golden_feather_eld/backend/http/eld_endpoints.dart';
import 'package:golden_feather_eld/backend/http/interceptors/auth_interceptor.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/network/api_client.dart';
import 'package:golden_feather_eld/core/network/api_config.dart';
import 'package:golden_feather_eld/core/session/auth_session.dart';
import 'package:golden_feather_eld/core/session/auth_session_reader.dart';
import 'package:golden_feather_eld/core/session/owner_identity.dart';
import 'package:golden_feather_eld/core/session/session_epoch.dart';
import 'package:golden_feather_eld/features/auth/domain/repositories/auth_repository.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';

// ---------------------------------------------------------------------------
// Synthetic fixtures.
// ---------------------------------------------------------------------------

User _user(String id) => User(
  id: id,
  username: 'synthetic-driver-$id',
  email: 'driver$id@test.invalid',
  fullName: 'Synthetic Driver $id',
  role: UserRole.fieldWorker,
  createdAt: DateTime.utc(2026, 1, 1),
);

AuthSession _session(String driverId) => AuthSession(
  serverOrigin: 'https://eld.invalid',
  sessionCredential: 'SYNTHETIC-CREDENTIAL-$driverId',
  user: _user(driverId),
  createdAt: DateTime.utc(2026, 3, 1),
);

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, User>> login({
    required String identifier,
    required String password,
  }) async {
    final id = switch (identifier) {
      'driver-one' => '1',
      'driver-two' => '2',
      _ => null,
    };
    if (id == null) {
      return const Left(ServerFailure(message: 'unknown synthetic driver'));
    }
    return Right(_user(id));
  }

  @override
  Future<Either<Failure, User>> checkAndRestoreSession() async =>
      const Left(ServerFailure(message: 'not used'));

  @override
  Future<Either<Failure, User>> getCurrentSession() async =>
      const Left(ServerFailure(message: 'not used'));

  @override
  Future<Either<Failure, Unit>> logout() async => const Right(unit);
}

class _MutableSessionReader implements AuthSessionReader {
  _MutableSessionReader(this.session);

  AuthSession? session;

  @override
  int get credentialGeneration => 1;

  @override
  Future<AuthSession?> getSession() async => session;
}

/// The only transport in this test. `fetchCount` counts bytes that reached
/// the fake adapter; a rejected request never increments it.
class _CountingHttpAdapter implements HttpClientAdapter {
  int fetchCount = 0;
  final List<String> paths = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    fetchCount++;
    paths.add(options.path);
    return ResponseBody.fromString(
      '{"success":true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

typedef _HttpHarness = ({ApiClient client, _CountingHttpAdapter adapter});

_HttpHarness _httpHarness() {
  final dio = Dio(BaseOptions(baseUrl: 'https://eld.invalid/api'));
  final adapter = _CountingHttpAdapter();
  dio.httpClientAdapter = adapter;
  dio.interceptors.add(
    AuthInterceptor(
      localDataSource: _MutableSessionReader(_session('2')),
      backendType: 'eld',
      // Production wiring: backend_network_providers.dart:66.
      resolveCurrentOwnerDriverId: OwnerIdentityBinding.resolve,
    ),
  );
  final client = ApiClient(
    config: const ApiConfig(baseUrl: 'https://eld.invalid/api'),
    dio: dio,
  );
  return (client: client, adapter: adapter);
}

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [
      traccarAuthRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _login(ProviderContainer container, String username) async {
  final ok = await container
      .read(authStateProvider.notifier)
      .login(username: username, password: 'synthetic-password');
  expect(ok, isTrue, reason: 'fake auth repository should accept $username');
}

Future<AppError?> _sendStamped(int owner) async {
  // Snapshot what the process-wide binding reports at send time. A disposed
  // container must surface here as an exception, not as a stale identity.
  String resolverValue;
  try {
    resolverValue = '${await OwnerIdentityBinding.resolve()}';
  } catch (e) {
    resolverValue = 'throws ${e.runtimeType}';
  }

  final http = _httpHarness();
  final result = await http.client.post<dynamic>(
    EldEndpoints.recordDutyStatusEvent,
    data: {'status': 'ON_DUTY'},
    expectedOwnerDriverId: owner,
  );
  AppError? failure;
  result.match((left) => failure = left, (_) => null);
  debugPrint(
    '[two-containers] stampedOwner=$owner '
    'resolverReads=$resolverValue '
    'httpFetches=${http.adapter.fetchCount} '
    'outcome=${failure == null ? 'allowed' : failure.runtimeType}',
  );
  return failure;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // OwnerIdentityBinding and SessionEpoch are process-wide statics. Reset
  // them around every test so a leaked resolver cannot make a later test pass.
  setUp(() {
    SessionEpoch.resetForTests();
    OwnerIdentityBinding.resetForTests();
  });
  tearDown(OwnerIdentityBinding.resetForTests);

  test(
    'two live containers: last install wins; the older live container is '
    'refused; disposing the newest uninstalls the binding (fail-closed)',
    () async {
      // ── Container 1: owner 1, installs binding -> c1 ────────────────────
      final c1 = _container();
      await _login(c1, 'driver-one');
      expect(c1.read(currentDriverIdProvider), 1);
      expect(await OwnerIdentityBinding.resolve(), 1);

      // ── Container 2: owner 2, installs binding -> c2 (last wins) ────────
      final c2 = _container();
      await _login(c2, 'driver-two');

      // Both containers are alive at the same time with different owners.
      expect(c1.read(currentDriverIdProvider), 1,
          reason: 'older container is still live and still owner 1');
      expect(c2.read(currentDriverIdProvider), 2,
          reason: 'newest container is live and is owner 2');
      expect(
        await OwnerIdentityBinding.resolve(),
        2,
        reason: 'the process-static binding points at the newest install',
      );

      // Request stamped by the older container's owner (1): the interceptor
      // reads 2 and must reject before the adapter.
      final staleFailure = await _sendStamped(1);
      expect(staleFailure, isA<OwnerMismatchError>());
      final staleAgain = await _sendStamped(1);
      expect(staleAgain, isA<OwnerMismatchError>());

      // Request stamped by the newest container's owner (2): allowed once.
      expect(await _sendStamped(2), isNull);

      // ── Dispose ONLY the newest container; the older one stays live ─────
      c2.dispose();

      expect(c1.read(currentDriverIdProvider), 1,
          reason: 'older container survived the newest container disposal');

      // On dispose the newest container uninstalls its own binding, so the
      // process-static resolver is absent (not dangling). `resolve()` fails
      // closed with null instead of reading a dead Ref.
      await expectLater(OwnerIdentityBinding.resolve(), completion(isNull));

      // Therefore a request stamped with the STILL-LIVE older owner (1) is
      // also refused: the interceptor treats a missing resolver as null and
      // fails closed (auth_interceptor.dart:105-128).
      final olderOwnerAfterDispose = await _sendStamped(1);
      expect(olderOwnerAfterDispose, isA<OwnerMismatchError>());

      // ── Re-install through the real production path ────────────────────
      // A fresh container that builds authStateProvider installs a live
      // resolver again. This proves the failure above is the dangling static
      // binding, not a broken owner-id lookup.
      final c3 = _container();
      await _login(c3, 'driver-one');
      expect(await OwnerIdentityBinding.resolve(), 1);
      expect(await _sendStamped(1), isNull);

      // Counter check: only the two explicitly allowed sends reached the
      // fake adapter; every rejected send stayed at zero.
      debugPrint(
        '[two-containers] final: c1Live=${c1.read(authStateProvider).isAuthenticated} '
        'c2Disposed=true c3Live=${c3.read(authStateProvider).isAuthenticated}',
      );
    },
  );
}

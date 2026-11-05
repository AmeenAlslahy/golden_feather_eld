// P0 audit — local verification of the owner-identity resolver path.
//
// This file is a NEW, isolated local test. It never touches a real server,
// device, BLE stack or stored user data. The HTTP adapter below is an
// in-memory fake; its body is synthetic (`{"success":true}`) and no
// credential of a real user is used.
//
// What it exercises (as close to production as possible):
//   authStateProvider (real build + real OwnerIdentityBinding.install)
//     -> OwnerIdentityBinding.resolve()
//     -> AuthInterceptor (real pre-dispatch fence)
//     -> ApiClient (real OwnerMismatchSignal -> OwnerMismatchError mapping)
//     -> EldDutyStatusBackend (real /eld/hos POST)
//     -> TraccarRemoteEventDispatcher (real _authorize / _mapError)
//     -> SyncEngine + MemoryOfflineQueue (real defer / release / send)
//
// It deliberately does NOT prove Release/Profile behavior. It runs under
// `flutter test` (Debug assertions enabled); the resolver reads through
// `Ref.container`, which avoids the Debug-only circular-dependency assertion
// while preserving live identity semantics.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:golden_feather_eld/app/di/app_providers.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/sub/eld_duty_status_backend.dart';
import 'package:golden_feather_eld/backend/contracts/daily_logs_backend.dart';
import 'package:golden_feather_eld/backend/contracts/duty_status_backend.dart';
import 'package:golden_feather_eld/backend/contracts/dvir_backend.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/backend/http/eld_endpoints.dart';
import 'package:golden_feather_eld/backend/http/interceptors/auth_interceptor.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/network/api_client.dart';
import 'package:golden_feather_eld/core/network/api_config.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/session/auth_session.dart';
import 'package:golden_feather_eld/core/session/auth_session_reader.dart';
import 'package:golden_feather_eld/core/session/owner_identity.dart';
import 'package:golden_feather_eld/core/session/session_epoch.dart';
import 'package:golden_feather_eld/core/time/time_authority.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/auth/domain/repositories/auth_repository.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/sync/data/repositories/memory_offline_queue.dart';
import 'package:golden_feather_eld/features/sync/data/repositories/traccar_remote_event_dispatcher.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/dispatch_auth.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/quarantine_record.dart';
import 'package:golden_feather_eld/features/sync/domain/usecases/sync_engine.dart';

// ---------------------------------------------------------------------------
// Synthetic fixtures (no real users, credentials, or servers).
// ---------------------------------------------------------------------------

User _user(String id) => User(
  id: id,
  username: 'test-driver-$id',
  email: 'driver$id@test.invalid',
  fullName: 'Test Driver $id',
  role: UserRole.fieldWorker,
  createdAt: DateTime.utc(2026, 1, 1),
);

AuthSession _session(String driverId) => AuthSession(
  serverOrigin: 'https://eld.invalid',
  sessionCredential: 'SYNTHETIC-CREDENTIAL-$driverId',
  user: _user(driverId),
  createdAt: DateTime.utc(2026, 3, 1),
);

/// Auth repository fake: the only job is to let the real [AuthNotifier]
/// produce an authenticated state without any network call.
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
      return const Left(ServerFailure(message: 'unknown test driver'));
    }
    return Right(_user(id));
  }

  @override
  Future<Either<Failure, User>> checkAndRestoreSession() async =>
      const Left(ServerFailure(message: 'not used in this test'));

  @override
  Future<Either<Failure, User>> getCurrentSession() async =>
      const Left(ServerFailure(message: 'not used in this test'));

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

/// The real last-mile adapter is replaced. It counts how many requests
/// actually reached the transport, so `fetchCount == 0` means no byte left
/// the app.
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

class _Clock implements TimeAuthority {
  @override
  Future<void> initialize() async {}

  @override
  DateTime nowUtc() => DateTime.utc(2026, 3, 1);

  @override
  Duration get monotonicElapsed => Duration.zero;

  @override
  TrustLevel get trustLevel => TrustLevel.serverSynced;

  @override
  Future<bool> resync() async => true;
}

class _CountingDispatcher implements RemoteEventDispatcher {
  _CountingDispatcher(this.inner);

  final RemoteEventDispatcher inner;

  /// Calls into the dispatcher. A call may still be fenced before HTTP, so
  /// this is NOT a count of network sends.
  int attempts = 0;

  @override
  Future<Either<Failure, bool>> dispatch(PendingEvent event) {
    attempts++;
    return inner.dispatch(event);
  }
}

/// Counts entries into each mutating [DutyStatusBackend] method.
///
/// A counter here means "the dispatcher reached the backend layer". It does
/// NOT mean an HTTP request left the app: `EldDutyStatusBackend` calls
/// `ApiClient`, and the real `AuthInterceptor` may still reject before the
/// adapter (see `fetchCount` on [_CountingHttpAdapter]).
class _CountingDutyStatusBackend implements DutyStatusBackend {
  _CountingDutyStatusBackend(this.inner, {this.beforeLegacyDutyStatus});

  final DutyStatusBackend inner;

  /// Optional hook fired after the backend is entered but before the real
  /// `ApiClient` call. Used to simulate an identity switch inside the
  /// `_authorize` -> HTTP window.
  final Future<void> Function()? beforeLegacyDutyStatus;

  int recordCalls = 0;
  int updateCalls = 0;
  int legacyDutyStatusCalls = 0;
  int legacyGenericCalls = 0;

  /// All mutating calls that reached the backend layer.
  int get mutatingCalls =>
      recordCalls + updateCalls + legacyDutyStatusCalls + legacyGenericCalls;

  @override
  Future<Result<RawJson>> record(RawJson event) {
    recordCalls++;
    return inner.record(event);
  }

  @override
  Future<Result<RawJson>> update({
    required DutyStatusId statusId,
    required RawJson update,
  }) {
    updateCalls++;
    return inner.update(statusId: statusId, update: update);
  }

  @override
  Future<Result<RawJson>> getGraphGrid({
    DriverId? driverId,
    required DateTime logDate,
  }) => inner.getGraphGrid(driverId: driverId, logDate: logDate);

  @override
  Future<Result<void>> submitLegacyDutyStatusEvent(
    int driverId,
    RawJson payload, {
    int? expectedOwnerDriverId,
  }) async {
    legacyDutyStatusCalls++;
    final hook = beforeLegacyDutyStatus;
    if (hook != null) await hook();
    return inner.submitLegacyDutyStatusEvent(
      driverId,
      payload,
      expectedOwnerDriverId: expectedOwnerDriverId,
    );
  }

  @override
  Future<Result<void>> submitLegacyGenericEvent(
    RawJson payload, {
    int? expectedOwnerDriverId,
  }) {
    legacyGenericCalls++;
    return inner.submitLegacyGenericEvent(
      payload,
      expectedOwnerDriverId: expectedOwnerDriverId,
    );
  }
}

/// These backends are never expected to run in this test; any call is a
/// failure of the fence, not a valid path.
class _UnusedDailyLogs implements DailyLogsBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected DailyLogsBackend call: $invocation');
}

class _UnusedDvir implements DvirBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected DvirBackend call: $invocation');
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

ProviderContainer _containerWithAuth({bool autoDispose = true}) {
  final container = ProviderContainer(
    overrides: [
      traccarAuthRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
    ],
  );
  if (autoDispose) {
    addTearDown(container.dispose);
  }
  return container;
}

Future<void> _login(ProviderContainer container, String username) async {
  final ok = await container
      .read(authStateProvider.notifier)
      .login(username: username, password: 'synthetic-password');
  expect(ok, isTrue, reason: 'fake auth repository should accept $username');
}

typedef _HttpHarness = ({ApiClient client, _CountingHttpAdapter adapter});

_HttpHarness _httpHarness({
  required _MutableSessionReader sessions,
  Future<int?> Function()? resolver,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://eld.invalid/api'));
  final adapter = _CountingHttpAdapter();
  dio.httpClientAdapter = adapter;
  dio.interceptors.add(
    AuthInterceptor(
      localDataSource: sessions,
      backendType: 'eld',
      // Production wiring: backend_network_providers.dart:66
      resolveCurrentOwnerDriverId: resolver ?? OwnerIdentityBinding.resolve,
    ),
  );
  final client = ApiClient(
    config: const ApiConfig(baseUrl: 'https://eld.invalid/api'),
    dio: dio,
  );
  return (client: client, adapter: adapter);
}

/// Mirrors `remoteEventDispatcherProvider` / `syncEngineProvider` observeAuth
/// (sync_providers.dart:120-130, 155-161): a container read, not the
/// authStateProvider's own Ref, so this path does not itself create a cycle.
Future<DispatchAuthContext> _observeAuth(ProviderContainer container) async {
  final auth = container.read(authStateProvider);
  return DispatchAuthContext(
    driverId: container.read(currentDriverIdProvider),
    transitioning: auth.transitioning,
  );
}

/// Diagnostic snapshot per phase. Prints counters only (synthetic driver ids
/// are not printed), so the run shows actual values even when all assertions
/// pass.
Future<void> _printPhase(
  String phase, {
  required _CountingDispatcher dispatcher,
  required _CountingDutyStatusBackend backend,
  required _CountingHttpAdapter adapter,
  required MemoryOfflineQueue queue,
}) async {
  final pending = await queue.getPending();
  final deferred = await queue.getDeferred();
  final state = deferred.length == 1
      ? deferred.single.state.name
      : 'n/a(${deferred.length})';
  final reason = deferred.length == 1 ? deferred.single.reason : 'n/a';
  debugPrint(
    '[C/$phase] '
    'dispatcherCalls=${dispatcher.attempts} '
    'backendMutatingCalls=${backend.mutatingCalls} '
    '(record=${backend.recordCalls}, '
    'update=${backend.updateCalls}, '
    'legacyDuty=${backend.legacyDutyStatusCalls}, '
    'legacyGeneric=${backend.legacyGenericCalls}) '
    'httpFetches=${adapter.fetchCount} '
    'pending=${pending.length} '
    'deferred=${deferred.length} '
    'state=$state '
    'reason=$reason',
  );
}

Future<int?> _throwingResolver() async =>
    throw StateError('synthetic resolver failure');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // OwnerIdentityBinding and SessionEpoch are process-wide statics: isolate
  // every test from the previous one.
  setUp(() {
    SessionEpoch.resetForTests();
    OwnerIdentityBinding.resetForTests();
  });
  tearDown(OwnerIdentityBinding.resetForTests);

  test(
    'A. the real resolver installed by authStateProvider returns the LIVE '
    'owner id (no CircularDependencyError)',
    () async {
      final container = _containerWithAuth();

      // Builds authStateProvider, which runs
      // `OwnerIdentityBinding.install(() => _readCurrentOwnerDriverId(ref))`
      // at auth_state_provider.dart:120.
      expect(container.read(authStateProvider).status, AuthStatus.initial);
      await _login(container, 'driver-two');
      expect(
        container.read(currentDriverIdProvider),
        2,
        reason: 'fallback to user.id for a non-admin '
            '(auth_state_provider.dart:178)',
      );

      expect(
        await OwnerIdentityBinding.resolve(),
        2,
        reason: 'the production resolver reads live through Ref.container and '
            'no longer trips the Debug circular-dependency assert',
      );

      // Live, not a snapshot: the same installed resolver must follow an
      // identity transition.
      await _login(container, 'driver-one');
      expect(container.read(currentDriverIdProvider), 1);
      expect(await OwnerIdentityBinding.resolve(), 1);
    },
  );

  test(
    'B1. matching owner: the real resolver lets the request reach the fake '
    'adapter exactly once',
    () async {
      final container = _containerWithAuth();
      await _login(container, 'driver-two');

      final sessions = _MutableSessionReader(_session('2'));
      final http = _httpHarness(sessions: sessions);

      final result = await http.client.post<dynamic>(
        EldEndpoints.recordDutyStatusEvent,
        data: const {'driverId': 2, 'status': 'ON_DUTY'},
        // Matches container.read(currentDriverIdProvider) == 2 exactly.
        expectedOwnerDriverId: 2,
      );

      AppError? failure;
      result.match((left) => failure = left, (_) => null);

      expect(failure, isNull);
      expect(result.isRight(), isTrue);
      expect(http.adapter.fetchCount, 1);
      expect(http.adapter.paths.single, EldEndpoints.recordDutyStatusEvent);
      expect(await OwnerIdentityBinding.resolve(), 2);
    },
  );

  test(
    'B2. mismatching owner: the real resolver blocks before the adapter',
    () async {
      final container = _containerWithAuth();
      await _login(container, 'driver-two');

      // Session is valid; only the ownership stamp differs.
      final sessions = _MutableSessionReader(_session('2'));
      final http = _httpHarness(sessions: sessions);

      final result = await http.client.post<dynamic>(
        EldEndpoints.recordDutyStatusEvent,
        data: const {'driverId': 1, 'status': 'ON_DUTY'},
        expectedOwnerDriverId: 1,
      );

      AppError? failure;
      result.match((left) => failure = left, (_) => null);

      expect(failure, isA<OwnerMismatchError>());
      expect(
        http.adapter.fetchCount,
        0,
        reason: 'rejected inside the interceptor, before the adapter',
      );
      expect(await OwnerIdentityBinding.resolve(), 2);
    },
  );

  test(
    'B3. independent control: a null resolver blocks the send even when a '
    'valid session is present',
    () async {
      final sessions = _MutableSessionReader(_session('2'));
      final http = _httpHarness(sessions: sessions, resolver: () async => null);

      final result = await http.client.post<dynamic>(
        EldEndpoints.recordDutyStatusEvent,
        data: const {'driverId': 2, 'status': 'ON_DUTY'},
        expectedOwnerDriverId: 2,
      );

      AppError? failure;
      result.match((left) => failure = left, (_) => null);

      expect(
        failure,
        isA<OwnerMismatchError>(),
        reason: 'null owner != stamped owner -> fail-closed rejection',
      );
      expect(http.adapter.fetchCount, 0);
    },
  );

  test(
    'B4. independent control: a resolver exception blocks the send with the '
    'fake adapter untouched',
    () async {
      final sessions = _MutableSessionReader(_session('2'));
      final http = _httpHarness(
        sessions: sessions,
        resolver: _throwingResolver,
      );

      final result = await http.client.post<dynamic>(
        EldEndpoints.recordDutyStatusEvent,
        data: const {'driverId': 2, 'status': 'ON_DUTY'},
        expectedOwnerDriverId: 2,
      );

      AppError? failure;
      result.match((left) => failure = left, (_) => null);

      expect(
        failure,
        isA<OwnerMismatchError>(),
        reason: 'resolver threw -> AuthInterceptor treats it as null '
            '(auth_interceptor.dart:105-128) -> OwnerMismatchSignal -> '
            'ApiClient maps it (api_client.dart:299-308)',
      );
      expect(
        http.adapter.fetchCount,
        0,
        reason: 'rejected inside the interceptor, before the adapter',
      );
    },
  );

  test(
    'C. wrong-owner event is deferred, released on the session switch, then '
    'sent exactly once through the real binding',
    () async {
      final container = _containerWithAuth();
      await _login(container, 'driver-two');

      final sessions = _MutableSessionReader(_session('2'));
      final http = _httpHarness(sessions: sessions);

      final backend = _CountingDutyStatusBackend(
        EldDutyStatusBackend(http.client),
      );
      final queue = MemoryOfflineQueue();
      final dispatcher = _CountingDispatcher(
        TraccarRemoteEventDispatcher(
          backend,
          _UnusedDailyLogs(),
          _UnusedDvir(),
          sessions,
          observeAuth: () => _observeAuth(container),
        ),
      );
      final engine = SyncEngine(
        queue: queue,
        dispatcher: dispatcher,
        timeAuthority: _Clock(),
        observeAuth: () => _observeAuth(container),
      );

      final event = PendingEvent(
        id: 'evt-owned-by-driver-1',
        type: 'duty_status',
        payload: const {'ownerDriverId': 1, 'status': 'ON_DUTY'},
        createdAt: DateTime.utc(2026, 3, 1),
      );
      await queue.enqueue(event);

      // --- Phase 1: session belongs to driver 2, event belongs to driver 1.
      await engine.triggerSync();
      await _printPhase(
        'phase1',
        dispatcher: dispatcher,
        backend: backend,
        adapter: http.adapter,
        queue: queue,
      );

      expect(
        dispatcher.attempts,
        1,
        reason: 'the engine entered the dispatcher once',
      );
      expect(
        backend.mutatingCalls,
        0,
        reason: 'the pre-dispatch fence refused before any backend method '
            '(traccar_remote_event_dispatcher.dart:198 + 107-113)',
      );
      expect(
        http.adapter.fetchCount,
        0,
        reason: 'no HTTP request reached the fake adapter',
      );
      expect(await queue.getPending(), isEmpty);
      final deferred1 = await queue.getDeferred();
      expect(deferred1, hasLength(1));
      expect(deferred1.single.ownerDriverId, 1);
      expect(
        deferred1.single.state,
        StoredEventState.deferredOwnerMismatch,
      );
      expect(
        deferred1.single.reason,
        'deferred-owner-mismatch',
        reason: 'parked by the dispatcher pre-check, not by the HTTP fence',
      );

      // --- Driver 1 takes over the session (real login -> new epoch).
      await _login(container, 'driver-one');
      sessions.session = _session('1');
      expect(container.read(currentDriverIdProvider), 1);

      // --- Phase 2: the exact callback registered at
      // sync_providers.dart:194-197 (`(_) => engine.triggerSync()`).
      await engine.triggerSync();
      await _printPhase(
        'phase2',
        dispatcher: dispatcher,
        backend: backend,
        adapter: http.adapter,
        queue: queue,
      );

      expect(
        dispatcher.attempts,
        2,
        reason: 'releaseEligible released it to pending '
            '(sync_engine.dart:96-123) and it was dispatched again',
      );
      expect(
        backend.legacyDutyStatusCalls,
        1,
        reason: 'owner == session driver, so the pre-dispatch fence passed '
            'and _dispatchDutyStatus reached the backend',
      );
      expect(backend.mutatingCalls, 1);
      expect(backend.recordCalls, 0);
      expect(backend.updateCalls, 0);
      expect(backend.legacyGenericCalls, 0);
      expect(
        http.adapter.fetchCount,
        1,
        reason: 'the live resolver matched owner 1 at send time, so exactly '
            'one request reached the fake adapter',
      );
      expect(http.adapter.paths.single, EldEndpoints.recordDutyStatusEvent);
      expect(
        await queue.getDeferred(),
        isEmpty,
        reason: 'the event settled successfully and left the queue',
      );
      expect(await queue.getPending(), isEmpty);

      // --- Phase 3: another trigger must not duplicate the local send.
      await engine.triggerSync();
      await _printPhase(
        'phase3',
        dispatcher: dispatcher,
        backend: backend,
        adapter: http.adapter,
        queue: queue,
      );

      expect(
        dispatcher.attempts,
        2,
        reason: 'no ready/deferred event remains, so the dispatcher is not '
            'entered again',
      );
      expect(backend.legacyDutyStatusCalls, 1);
      expect(backend.mutatingCalls, 1);
      expect(
        http.adapter.fetchCount,
        1,
        reason: 'no duplicate local send on the next trigger',
      );
      expect(await queue.getPending(), isEmpty);
      expect(await queue.getDeferred(), isEmpty);
      // Local no-duplicate check only; this is NOT a server-side
      // idempotency guarantee.
    },
  );

  test(
    'E. a session switch between _authorize and the HTTP call is caught by '
    'the send-time fence: no byte leaves',
    () async {
      final container = _containerWithAuth();
      await _login(container, 'driver-one');

      final sessions = _MutableSessionReader(_session('1'));
      final http = _httpHarness(sessions: sessions);

      final backend = _CountingDutyStatusBackend(
        EldDutyStatusBackend(http.client),
        beforeLegacyDutyStatus: () async {
          // The dispatcher already authorized owner 1; another identity takes
          // over before the request crosses the HTTP fence.
          await container.read(authStateProvider.notifier).logout();
          await _login(container, 'driver-two');
          sessions.session = _session('2');
        },
      );
      final queue = MemoryOfflineQueue();
      final dispatcher = _CountingDispatcher(
        TraccarRemoteEventDispatcher(
          backend,
          _UnusedDailyLogs(),
          _UnusedDvir(),
          sessions,
          observeAuth: () => _observeAuth(container),
        ),
      );
      final engine = SyncEngine(
        queue: queue,
        dispatcher: dispatcher,
        timeAuthority: _Clock(),
        observeAuth: () => _observeAuth(container),
      );

      await queue.enqueue(
        PendingEvent(
          id: 'evt-switched-before-http',
          type: 'duty_status',
          payload: const {'ownerDriverId': 1, 'status': 'ON_DUTY'},
          createdAt: DateTime.utc(2026, 3, 1),
        ),
      );

      await engine.triggerSync();
      await _printPhase(
        'session-switch',
        dispatcher: dispatcher,
        backend: backend,
        adapter: http.adapter,
        queue: queue,
      );

      expect(
        dispatcher.attempts,
        1,
        reason: 'the event existed once and was dispatched once',
      );
      expect(
        backend.legacyDutyStatusCalls,
        1,
        reason: 'the pre-dispatch fence passed under owner 1 before the switch',
      );
      expect(
        http.adapter.fetchCount,
        0,
        reason: 'the live resolver returned owner 2 at send time and the '
            'interceptor rejected before the adapter',
      );
      expect(container.read(currentDriverIdProvider), 2);
      expect(await queue.getPending(), isEmpty);
      final deferred = await queue.getDeferred();
      expect(deferred, hasLength(1));
      expect(deferred.single.ownerDriverId, 1);
      expect(
        deferred.single.state,
        StoredEventState.deferredOwnerMismatch,
      );
      expect(
        deferred.single.reason,
        'send-time-owner-mismatch',
        reason: 'produced only by the HTTP-fence mapping '
            '(traccar_remote_event_dispatcher.dart:127-137)',
      );
    },
  );

  test(
    'F. a disposed container fails closed; a replacement container '
    're-installs the process-static binding',
    () async {
      final first = _containerWithAuth(autoDispose: false);
      await _login(first, 'driver-two');
      expect(await OwnerIdentityBinding.resolve(), 2);

      first.dispose();

      int? disposedOwner;
      Object? disposedError;
      try {
        disposedOwner = await OwnerIdentityBinding.resolve();
      } catch (e) {
        disposedError = e;
      }
      expect(
        disposedError != null || disposedOwner == null,
        isTrue,
        reason: 'a disposed container must never yield an owner',
      );

      // The stale static binding is what production would still hold until
      // the next authStateProvider build. It must fail closed at the fence.
      final staleSessions = _MutableSessionReader(_session('2'));
      final staleHttp = _httpHarness(sessions: staleSessions);
      final staleResult = await staleHttp.client.post<dynamic>(
        EldEndpoints.recordDutyStatusEvent,
        data: const {'driverId': 2, 'status': 'ON_DUTY'},
        expectedOwnerDriverId: 2,
      );
      AppError? staleFailure;
      staleResult.match((left) => staleFailure = left, (_) => null);
      expect(staleFailure, isA<OwnerMismatchError>());
      expect(
        staleHttp.adapter.fetchCount,
        0,
        reason: 'a dead container must not authorize any send',
      );

      // A new container installs its own resolver; newest install wins.
      final second = _containerWithAuth();
      await _login(second, 'driver-one');
      expect(await OwnerIdentityBinding.resolve(), 1);

      final freshSessions = _MutableSessionReader(_session('1'));
      final freshHttp = _httpHarness(sessions: freshSessions);
      final freshResult = await freshHttp.client.post<dynamic>(
        EldEndpoints.recordDutyStatusEvent,
        data: const {'driverId': 1, 'status': 'ON_DUTY'},
        expectedOwnerDriverId: 1,
      );
      AppError? freshFailure;
      freshResult.match((left) => freshFailure = left, (_) => null);
      expect(freshFailure, isNull);
      expect(freshHttp.adapter.fetchCount, 1);
    },
  );

  test(
    'G. logout clears the live owner and the next login returns the new '
    'owner (no stale reuse)',
    () async {
      final container = _containerWithAuth();
      await _login(container, 'driver-two');
      expect(await OwnerIdentityBinding.resolve(), 2);

      await container.read(authStateProvider.notifier).logout();
      expect(container.read(currentDriverIdProvider), isNull);
      expect(
        await OwnerIdentityBinding.resolve(),
        isNull,
        reason: 'the resolver is live, so it follows logout immediately',
      );

      await _login(container, 'driver-one');
      expect(container.read(currentDriverIdProvider), 1);
      expect(
        await OwnerIdentityBinding.resolve(),
        1,
        reason: 'the same static binding is reused for the new session '
            'without returning the previous owner',
      );
    },
  );
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/models/certify_dto.dart';
import 'package:golden_feather_eld/backend/contracts/daily_logs_backend.dart';
import 'package:golden_feather_eld/backend/contracts/dvir_backend.dart';
import 'package:golden_feather_eld/backend/contracts/contract_enums.dart';
import 'package:golden_feather_eld/backend/contracts/driver_session_backend.dart';
import 'package:golden_feather_eld/backend/contracts/duty_status_backend.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/time/time_authority.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:golden_feather_eld/core/session/auth_session.dart';
import 'package:golden_feather_eld/features/sync/data/repositories/memory_offline_queue.dart';
import 'package:golden_feather_eld/features/sync/data/repositories/traccar_remote_event_dispatcher.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/dispatch_auth.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/event_ownership.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/quarantine_record.dart';
import 'package:golden_feather_eld/features/sync/domain/usecases/sync_engine.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────

User _user(String id) => User(
  id: id,
  fullName: 'Driver $id',
  email: '$id@demo.com',
  username: id,
  role: UserRole.fieldWorker,
  createdAt: DateTime.utc(2026, 1, 1),
);

AuthSession _session(String driverId) => AuthSession(
  serverOrigin: 'https://api.example.com',
  sessionCredential: 'CRED-$driverId',
  user: _user(driverId),
  createdAt: DateTime.utc(2026, 3, 1),
);

class _SessionDS implements AuthLocalDataSource {
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

class _DutyBackend implements DutyStatusBackend {
  int calls = 0;
  final List<Map<String, dynamic>> bodies = [];

  @override
  Future<Result<void>> submitLegacyDutyStatusEvent(
    int driverId,
    RawJson payload, {
    int? expectedOwnerDriverId,
  }) async {
    calls++;
    bodies.add(Map<String, dynamic>.from(payload));
    return ok(null);
  }

  @override
  Future<Result<void>> submitLegacyGenericEvent(
    RawJson payload, {
    int? expectedOwnerDriverId,
  }) async {
    calls++;
    return ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _LogsBackend implements DailyLogsBackend {
  int certifyCalls = 0;
  int formCalls = 0;
  int lastCertifyDriverId = -1;
  Completer<void>? certifyGate;

  @override
  Future<Result<CertifyResponseDto>> certify(
    CertifyRequestDto request, {
    int? expectedOwnerDriverId,
  }) async {
    certifyCalls++;
    // الوثيقة: هوية المالك تُثبت عبر expectedOwnerDriverId (جسم الطلب لا
    // يحمل driverId بعد الآن).
    lastCertifyDriverId = expectedOwnerDriverId ?? -1;
    final gate = certifyGate;
    if (gate != null) await gate.future;
    return ok(
      CertifyResponseDto(
        dailyLogId: request.dailyLogId,
        certificationStatus: 'CERTIFIED',
        isCertified: true,
      ),
    );
  }

  @override
  Future<Result<RawJson>> saveForm({
    required DailyLogId logId,
    required RawJson form,
    int? expectedOwnerDriverId,
  }) async {
    formCalls++;
    return ok(<String, dynamic>{});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _DvirBackend implements DvirBackend {
  int createCalls = 0;

  @override
  Future<Result<void>> create(
    RawJson report, {
    int? expectedOwnerDriverId,
  }) async {
    createCalls++;
    return ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _Clock implements TimeAuthority {
  @override
  Future<void> initialize() async {}

  @override
  DateTime nowUtc() => DateTime.utc(2026, 3, 1, 12);

  @override
  Duration get monotonicElapsed => Duration.zero;

  @override
  TrustLevel get trustLevel => TrustLevel.serverSynced;

  @override
  Future<bool> resync() async => true;
}

PendingEvent _event(String id, String type, Map<String, dynamic> payload) =>
    PendingEvent(
      id: id,
      type: type,
      payload: payload,
      createdAt: DateTime.utc(2026, 3, 1, 8),
    );

Map<String, dynamic> _certPayload({int? owner, int logId = 9}) => {
  'logId': logId,
  'certified': true,
  'signatureImage': 'c2ln', // base64 bytes (opaque to the dispatcher)
  if (owner != null) 'ownerDriverId': owner,
};

// ─── Harness ──────────────────────────────────────────────────────────────

class _Harness {
  final sessionDS = _SessionDS();
  final duty = _DutyBackend();
  final logs = _LogsBackend();
  final dvir = _DvirBackend();
  final queue = MemoryOfflineQueue();

  int? authDriverId;
  bool transitioning = false;
  final Map<int, int> cacheOwners = {};

  late final TraccarRemoteEventDispatcher dispatcher =
      TraccarRemoteEventDispatcher(
        duty,
        logs,
        dvir,
        sessionDS,
        observeAuth: () async => DispatchAuthContext(
          driverId: authDriverId,
          transitioning: transitioning,
        ),
        cachedLogOwner: (logId) async => cacheOwners[logId],
      );

  late final SyncEngine engine = SyncEngine(
    queue: queue,
    dispatcher: dispatcher,
    timeAuthority: _Clock(),
    observeAuth: () async => DispatchAuthContext(
      driverId: authDriverId,
      transitioning: transitioning,
    ),
  );

  Future<void> authAs(String driverId) async {
    await sessionDS.saveSession(_session(driverId));
    authDriverId = int.parse(driverId);
    transitioning = false;
  }

  Future<void> logout() async {
    await sessionDS.clearSession();
    authDriverId = null;
    transitioning = false;
  }

  Future<int> parkedTotal() async =>
      (await queue.getDeferred(limit: 1000)).length +
      (await queue.getQuarantined(limit: 1000)).length;
}

// ─── Tests ────────────────────────────────────────────────────────────────

void main() {
  group('dispatch ownership enforcement', () {
    test('T1: A event + B session → zero HTTP, parked as mismatch', () async {
      final h = _Harness();
      await h.queue.enqueue(
        _event('c1', 'certification', _certPayload(owner: 101)),
      );
      await h.authAs('202');

      await h.engine.triggerSync();

      expect(h.logs.certifyCalls, 0, reason: 'zero HTTP under B');
      expect(await h.queue.count, 0);
      final deferred = await h.queue.getDeferred();
      expect(deferred, hasLength(1));
      expect(deferred.single.ownerDriverId, 101);
      expect(deferred.single.state, StoredEventState.deferredOwnerMismatch);
      expect(await h.queue.getQuarantined(), isEmpty);
    });

    test('T2: A event + A session → allowed exactly once', () async {
      final h = _Harness();
      await h.queue.enqueue(
        _event('c1', 'certification', _certPayload(owner: 101)),
      );
      await h.authAs('101');

      await h.engine.triggerSync();

      expect(h.logs.certifyCalls, 1);
      expect(
        h.logs.lastCertifyDriverId,
        101,
        reason: 'sent strictly as the proven owner',
      );
      expect(await h.queue.count, 0);
      expect(await h.parkedTotal(), 0);
    });

    test('T3: unknown owner → quarantined, never dispatched', () async {
      final h = _Harness();
      await h.queue.enqueue(
        _event('f1', 'daily_log_form', {'logId': 55, 'form': {}}),
      );
      await h.authAs('202');

      await h.engine.triggerSync();

      expect(h.logs.formCalls, 0);
      expect(await h.queue.count, 0);
      final quarantined = await h.queue.getQuarantined();
      expect(quarantined, hasLength(1));
      expect(quarantined.single.ownerDriverId, isNull);
      expect(await h.queue.getDeferred(), isEmpty);
    });

    test('T4: logout mid-dispatch blocks the next event', () async {
      final h = _Harness();
      h.logs.certifyGate = Completer<void>();
      await h.queue.enqueue(
        _event('c1', 'certification', _certPayload(owner: 101)),
      );
      await h.queue.enqueue(
        _event('c2', 'certification', _certPayload(owner: 101)),
      );
      await h.authAs('101');

      unawaited(h.engine.triggerSync());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(
        h.logs.certifyCalls,
        1,
        reason: 'first dispatch authorized under A',
      );

      await h.logout(); // session gone mid-flight
      h.logs.certifyGate!.complete();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(
        h.logs.certifyCalls,
        1,
        reason: 'no new dispatch starts after logout',
      );
      final deferred = await h.queue.getDeferred();
      expect(deferred.map((r) => r.event.id), contains('c2'));
    });

    test('T5: owner returns → eligible event restored and sent', () async {
      final h = _Harness();
      await h.queue.enqueue(
        _event('c1', 'certification', _certPayload(owner: 101)),
      );
      await h.authAs('202');
      await h.engine.triggerSync();
      expect(await h.parkedTotal(), 1);

      await h.authAs('101');
      await h.engine.triggerSync();

      expect(h.logs.certifyCalls, 1);
      expect(h.logs.lastCertifyDriverId, 101);
      expect(await h.queue.count, 0);
      expect(await h.parkedTotal(), 0);
    });

    test('T7+T8: parked rows never retry, never deleted', () async {
      final h = _Harness();
      await h.queue.enqueue(
        _event('f1', 'daily_log_form', {'logId': 55, 'form': {}}),
      );
      await h.authAs('202');
      const before = 1;

      for (var i = 0; i < 3; i++) {
        await h.engine.triggerSync();
      }

      expect(h.logs.formCalls, 0, reason: 'T7: zero HTTP across cycles');
      final total = await h.queue.count + await h.parkedTotal();
      expect(total, before, reason: 'T8: no deletion');
      expect(await h.queue.getQuarantined(), hasLength(1));
    });

    test('T9: owner field and resolver agree (incl. canonical key)', () async {
      // Legacy slots still resolve.
      expect(
        EventOwnershipResolver.resolve(
          _event('d', 'duty_status', {'driverId': 101}),
        ).driverId,
        101,
      );
      // New canonical slot resolves for every type, including cert/form.
      expect(
        EventOwnershipResolver.resolve(
          _event('c', 'certification', _certPayload(owner: 202)),
        ).driverId,
        202,
      );
      expect(
        EventOwnershipResolver.resolve(
          _event('f', 'daily_log_form', {
            'logId': 1,
            'form': {},
            'ownerDriverId': 303,
          }),
        ).driverId,
        303,
      );
      // Legacy events without any slot stay UNKNOWN (never inferred).
      expect(
        EventOwnershipResolver.resolve(
          _event('c', 'certification', _certPayload()),
        ).evidence,
        OwnerEvidence.unknown,
      );
    });
  });

  group('P0 — offline co-driver switch routing', () {
    late _DriverSessionBackend session;
    late _DutyBackend duty;
    late _LogsBackend logs;
    late _DvirBackend dvir;
    late _SessionDS sessionDS;

    setUp(() {
      session = _DriverSessionBackend();
      duty = _DutyBackend();
      logs = _LogsBackend();
      dvir = _DvirBackend();
      sessionDS = _SessionDS();
    });

    TraccarRemoteEventDispatcher build({_DriverSessionBackend? backend}) =>
        TraccarRemoteEventDispatcher(
          duty,
          logs,
          dvir,
          sessionDS,
          readDriverSessionBackend: backend == null ? null : () => backend,
          observeAuth: () async =>
              const DispatchAuthContext(driverId: 101, transitioning: false),
        );

    PendingEvent switchEvent({int? owner}) =>
        _event('sw1', 'switch_primary_driver', {
          'coDriverId': 55,
          'reason': 'offline shift change',
          if (owner != null) 'ownerDriverId': owner,
        });

    test(
      'legacy action first without reason (OAS-exact) under proven owner',
      () async {
        final result = await build(
          backend: session,
        ).dispatch(switchEvent(owner: 101));

        expect(result.isRight(), isTrue);
        expect(session.calls, 1);
        expect(session.lastAction, DutyStatusAction.legacySwitch);
        expect(session.lastCoDriverId, 55);
        expect(
          session.lastReason,
          isNull,
          reason: 'legacy لا يقبل reason في OAS',
        );
      },
    );

    test(
      'legacy failure falls back to switchPrimary with the reason',
      () async {
        session.legacyResult = err(const ServerError(code: '400'));

        final result = await build(
          backend: session,
        ).dispatch(switchEvent(owner: 101));

        expect(result.isRight(), isTrue);
        expect(session.calls, 2);
        expect(session.lastAction, DutyStatusAction.switchPrimary);
        expect(session.lastReason, 'offline shift change');
      },
    );

    test(
      'missing backend → deterministic rejection, never the generic route',
      () async {
        final result = await build().dispatch(switchEvent(owner: 101));

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<RejectedFailure>());
          expect(
            (failure as RejectedFailure).code,
            'switch_co_driver_unroutable',
            reason: 'كان يسقط على default فيضيع التبديل بلا أثر',
          );
        }, (_) => fail('expected a rejection'));
        expect(session.calls, 0);
      },
    );

    test('unproven owner is fenced before any switch call happens', () async {
      final result = await build(
        backend: session,
      ).dispatch(switchEvent(owner: null));

      expect(session.calls, 0, reason: 'الحجر يسبق التوجيه');
      expect(result.isLeft(), isTrue);
    });
  });
}

class _DriverSessionBackend implements DriverSessionBackend {
  int calls = 0;
  DutyStatusAction? lastAction;
  int? lastCoDriverId;
  String? lastReason;
  Result<void> legacyResult = ok(null);
  Result<void> switchResult = ok(null);

  @override
  Future<Result<void>> switchPrimaryDriver({
    required DutyStatusAction action,
    required DriverId coDriverId,
    String? reason,
  }) async {
    calls++;
    lastAction = action;
    lastCoDriverId = coDriverId.value;
    lastReason = reason;
    return action == DutyStatusAction.legacySwitch
        ? legacyResult
        : switchResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

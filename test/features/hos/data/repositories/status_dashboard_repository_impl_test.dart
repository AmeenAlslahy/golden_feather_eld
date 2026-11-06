import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/contracts/status_dashboard_backend.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/duty_status/weekly_recap.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/hos/data/datasources/dashboard_local_cache.dart';
import 'package:golden_feather_eld/features/hos/data/repositories/status_dashboard_repository_impl.dart';

class _Backend implements StatusDashboardBackend {
  _Backend({this.recap, this.dashboard, this.fail = false, this.completer});

  final Completer<Result<StatusDashboard>>? completer;

  final WeeklyRecap? recap;
  StatusDashboard? dashboard;
  final bool fail;
  int dashboardCalls = 0;

  @override
  Future<Result<WeeklyRecap>> getWeeklyRecap({DriverId? driverId}) async {
    if (fail) return err(const ServerError(code: 'server.500'));
    return ok(recap!);
  }

  @override
  Future<Result<StatusDashboard>> getDashboard({DriverId? driverId}) async {
    dashboardCalls++;
    if (driverId == const DriverId(101) && completer != null && !completer!.isCompleted) {
      return completer!.future;
    }
    if (fail) return err(const ServerError(code: 'server.500'));
    return ok(dashboard ?? _sampleDashboard(driverId: driverId?.value ?? 101));
  }

  @override
  Future<Result<StatusDashboard?>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
    DriverId? driverId,
    VehicleId? vehicleId,
    double? latitude,
    double? longitude,
  }) async {
    throw UnimplementedError();
  }
}

class _Network implements NetworkInfo {
  _Network(this.isConnected);

  @override
  final bool isConnected;

  @override
  Stream<bool> get onConnectionChange => const Stream.empty();
}

class _Cache implements DashboardLocalCache {
  _Cache({this.recap});

  WeeklyRecap? recap;

  @override
  Future<void> clear() async {
    recap = null;
  }

  @override
  CachedDashboard? loadDashboard() => null;

  @override
  WeeklyRecap? loadRecap() => recap;

  @override
  Future<void> saveDashboard(StatusDashboard dashboard,
      {required DateTime takenAt}) async {}

  @override
  Future<void> saveRecap(WeeklyRecap value) async {
    recap = value;
  }
}

WeeklyRecap _recap() => WeeklyRecap(
      cycleRule: CycleRule.usa70_8,
      cycleUsed: const Duration(hours: 41, minutes: 30),
      cycleRemaining: const Duration(hours: 28, minutes: 30),
      availableTomorrow: const Duration(hours: 10),
      days: [
        RecapDay(
          date: DateTime(2026, 10, 20),
          dayOfWeek: 'Tue',
          driving: const Duration(hours: 5),
          onDuty: const Duration(hours: 3),
          totalWork: const Duration(hours: 8),
        ),
      ],
    );

void main() {
  group('getWeeklyRecap never fabricates a recap', () {
    test('server failure with no cached recap -> NoRecapSnapshotFailure',
        () async {
      final repo = StatusDashboardRepositoryImpl(
        _Backend(fail: true),
        _Network(true),
        disk: _Cache(),
      );

      final result = await repo.getWeeklyRecap();

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<NoRecapSnapshotFailure>());
    });

    test('offline with no cached recap -> NoRecapSnapshotFailure', () async {
      final repo = StatusDashboardRepositoryImpl(
        _Backend(recap: _recap()),
        _Network(false),
        disk: _Cache(),
      );

      final result = await repo.getWeeklyRecap();

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<NoRecapSnapshotFailure>());
    });

    test('server failure with cached recap -> cached values verbatim',
        () async {
      final cached = _recap();
      final repo = StatusDashboardRepositoryImpl(
        _Backend(fail: true),
        _Network(true),
        disk: _Cache(recap: cached),
      );

      final result = await repo.getWeeklyRecap();

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable(), same(cached));
      expect(result.getRight().toNullable()!.availableTomorrow,
          const Duration(hours: 10));
    });

    test('offline with cached recap -> cached values verbatim', () async {
      final cached = _recap();
      final repo = StatusDashboardRepositoryImpl(
        _Backend(recap: _recap()),
        _Network(false),
        disk: _Cache(recap: cached),
      );

      final result = await repo.getWeeklyRecap();

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable(), same(cached));
    });

    test('successful fetch is returned and persisted', () async {
      final fresh = _recap();
      final cache = _Cache();
      final repo = StatusDashboardRepositoryImpl(
        _Backend(recap: fresh),
        _Network(true),
        disk: cache,
      );

      final result = await repo.getWeeklyRecap();

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable(), same(fresh));
      expect(cache.recap, same(fresh));
    });
  });

  group('getDashboard deduplication and burst throttle', () {
    test('deduplicates concurrent in-flight requests', () async {
      final backend = _Backend(dashboard: _sampleDashboard());
      final repo = StatusDashboardRepositoryImpl(
        backend,
        _Network(true),
        disk: _Cache(),
      );

      final results = await Future.wait([
        repo.getDashboard(driverId: const DriverId(101)),
        repo.getDashboard(driverId: const DriverId(101)),
        repo.getDashboard(driverId: const DriverId(101)),
      ]);

      expect(results.every((r) => r.isRight()), isTrue);
      expect(backend.dashboardCalls, 1);
    });

    test('throttles rapid consecutive requests within 2 seconds', () async {
      DateTime simulatedTime = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final backend = _Backend(dashboard: _sampleDashboard());
      final repo = StatusDashboardRepositoryImpl(
        backend,
        _Network(true),
        disk: _Cache(),
        trustedNowUtc: () => simulatedTime,
      );

      final r1 = await repo.getDashboard(driverId: const DriverId(101));
      expect(r1.isRight(), isTrue);
      expect(backend.dashboardCalls, 1);

      simulatedTime = simulatedTime.add(const Duration(milliseconds: 500));
      final r2 = await repo.getDashboard(driverId: const DriverId(101));
      expect(r2.isRight(), isTrue);
      expect(backend.dashboardCalls, 1);

      simulatedTime = simulatedTime.add(const Duration(milliseconds: 2000));
      final r3 = await repo.getDashboard(driverId: const DriverId(101));
      expect(r3.isRight(), isTrue);
      expect(backend.dashboardCalls, 2);
    });
  });

  group('Cache Invalidation Scenarios', () {
    test('driver change invalidates throttle within 2s window', () async {
      DateTime simulatedTime = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final backend = _Backend(dashboard: _sampleDashboard());
      final repo = StatusDashboardRepositoryImpl(
        backend,
        _Network(true),
        disk: _Cache(),
        trustedNowUtc: () => simulatedTime,
      );

      final r1 = await repo.getDashboard(driverId: const DriverId(101));
      expect(r1.isRight(), isTrue);
      expect(backend.dashboardCalls, 1);

      // Calling with different driverId immediately (0s elapsed) must hit backend
      final r2 = await repo.getDashboard(driverId: const DriverId(202));
      expect(r2.isRight(), isTrue);
      expect(backend.dashboardCalls, 2);
    });

    test('clearCache resets throttle within 2s window', () async {
      DateTime simulatedTime = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final backend = _Backend(dashboard: _sampleDashboard());
      final repo = StatusDashboardRepositoryImpl(
        backend,
        _Network(true),
        disk: _Cache(),
        trustedNowUtc: () => simulatedTime,
      );

      final r1 = await repo.getDashboard(driverId: const DriverId(101));
      expect(r1.isRight(), isTrue);
      expect(backend.dashboardCalls, 1);

      await repo.clearCache();

      // Calling again with driverId 101 immediately must hit backend because cache was cleared
      final r2 = await repo.getDashboard(driverId: const DriverId(101));
      expect(r2.isRight(), isTrue);
      expect(backend.dashboardCalls, 2);
    });

    test(
      'in-flight request completing after clearCache: does NOT repopulate cache or return stale result',
      () async {
        final completer = Completer<Result<StatusDashboard>>();
        final backend = _Backend(completer: completer);
        final repo = StatusDashboardRepositoryImpl(
          backend,
          _Network(true),
          disk: _Cache(),
        );

        // 1. Start in-flight request for driver 101
        final inFlight = repo.getDashboard(driverId: const DriverId(101));
        expect(backend.dashboardCalls, 1);

        // 2. Clear cache while in-flight (e.g. driver logout)
        await repo.clearCache();
        expect(repo.cachedDashboard, isNull);

        // 3. Complete the in-flight network request
        completer.complete(ok(_sampleDashboard()));
        final res = await inFlight;

        // Verify: stale request is aborted, does NOT return stale Right, and does NOT populate cache
        expect(res.isLeft(), isTrue,
            reason: 'Result of request initiated before clearCache must be rejected');
        expect(
          repo.cachedDashboard,
          isNull,
          reason:
              'Epoch mechanism prevents in-flight request from repopulating cache after clearCache',
        );
      },
    );

    test(
      'driver change during in-flight request: does NOT populate cache with old driver data',
      () async {
        final completer = Completer<Result<StatusDashboard>>();
        final backend = _Backend(completer: completer);
        final repo = StatusDashboardRepositoryImpl(
          backend,
          _Network(true),
          disk: _Cache(),
        );

        // 1. Start in-flight request for driver 101
        final inFlight101 = repo.getDashboard(driverId: const DriverId(101));
        expect(backend.dashboardCalls, 1);

        // 2. Driver 202 requests dashboard while 101 is in-flight
        // Setting up a new backend response for driver 202
        backend.dashboard = _sampleDashboard(driverId: 202);
        final res202 = await repo.getDashboard(driverId: const DriverId(202));
        expect(res202.isRight(), isTrue);
        expect(backend.dashboardCalls, 2);
        expect(repo.cachedDashboard?.driver.id, const DriverId(202));

        // 3. Old in-flight request for driver 101 finishes
        completer.complete(ok(_sampleDashboard(driverId: 101)));
        final res101 = await inFlight101;

        // Old request must be rejected and must NOT overwrite driver 202's cache
        expect(res101.isLeft(), isTrue);
        expect(repo.cachedDashboard?.driver.id, const DriverId(202),
            reason: 'Old in-flight request for driver 101 must not overwrite driver 202 cache');
      },
    );

    test(
      'status change (cacheDashboard) during in-flight request: does NOT overwrite new status',
      () async {
        final completer = Completer<Result<StatusDashboard>>();
        final backend = _Backend(completer: completer);
        final repo = StatusDashboardRepositoryImpl(
          backend,
          _Network(true),
          disk: _Cache(),
        );

        // 1. Start in-flight request returning OFF_DUTY
        final inFlight = repo.getDashboard(driverId: const DriverId(101));
        expect(backend.dashboardCalls, 1);

        // 2. Driver changes status to ON_DUTY (POST succeeds, updates cacheDashboard)
        final newDashboard = _sampleDashboard(
          dutyStatus: DutyStatusCode.onDutyNotDriving,
          driverId: 101,
        );
        repo.cacheDashboard(newDashboard, takenAt: DateTime.utc(2026, 1, 1, 12, 0, 0));
        expect(repo.cachedDashboard?.currentDutyStatus, DutyStatusCode.onDutyNotDriving);

        // 3. Old in-flight GET completes with OFF_DUTY
        final oldDashboard = _sampleDashboard(
          dutyStatus: DutyStatusCode.offDuty,
          driverId: 101,
        );
        completer.complete(ok(oldDashboard));
        final res = await inFlight;

        // Old in-flight request must be aborted by epoch bump, and must NOT overwrite ON_DUTY
        expect(res.isLeft(), isTrue);
        expect(repo.cachedDashboard?.currentDutyStatus, DutyStatusCode.onDutyNotDriving,
            reason: 'Old in-flight GET must not overwrite fresh status update from cacheDashboard');
      },
    );

    test(
      'clearCache sets cachedDashboard to null immediately before any network call completes',
      () async {
        final backend = _Backend(dashboard: _sampleDashboard());
        final repo = StatusDashboardRepositoryImpl(
          backend,
          _Network(true),
          disk: _Cache(),
        );

        await repo.getDashboard(driverId: const DriverId(101));
        expect(repo.cachedDashboard, isNotNull);

        // clearCache immediately clears cachedDashboard in-memory (safety note)
        await repo.clearCache();
        expect(repo.cachedDashboard, isNull);
      },
    );
  });
}

StatusDashboard _sampleDashboard({
  int driverId = 101,
  DutyStatusCode dutyStatus = DutyStatusCode.onDutyNotDriving,
}) {
  return StatusDashboard(
    driver: DriverRef(
      id: DriverId(driverId),
      name: 'Ahmed',
      displayText: 'Ahmed - $driverId',
    ),
    operationalAlerts: const OperationalAlerts(
      toolIcon: false,
      warningTriangleIcon: false,
      connectionStatus: ConnectionStatus.ok,
    ),
    currentDutyStatus: dutyStatus,
    remainingCircle: const RemainingCircle(
      remaining: Duration(hours: 8, minutes: 37),
      label: 'Remaining',
      progress: 0.62,
    ),
    hosIndicators: const HosIndicators(
      drive: HosIndicator(
        label: 'DRIVE',
        value: Duration(hours: 2, minutes: 23),
        type: IndicatorType.used,
      ),
      shift: HosIndicator(
        label: 'SHIFT',
        value: Duration(hours: 5, minutes: 23),
        type: IndicatorType.used,
      ),
      breakTime: HosIndicator(
        label: 'BREAK',
        value: Duration(minutes: 30),
        type: IndicatorType.remaining,
      ),
      cycle: HosIndicator(
        label: 'CYCLE',
        value: Duration(hours: 61, minutes: 23),
        type: IndicatorType.used,
      ),
    ),
    regulatoryConstraints: const RegulatoryConstraints(
      ruleSet: CycleRule.usa70_8,
      limits: ['maxDrivingHours: 11'],
    ),
  );
}


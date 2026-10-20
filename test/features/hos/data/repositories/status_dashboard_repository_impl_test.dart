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
  _Backend({this.recap, this.fail = false});

  final WeeklyRecap? recap;
  final bool fail;

  @override
  Future<Result<WeeklyRecap>> getWeeklyRecap({DriverId? driverId}) async {
    if (fail) return err(const ServerError(code: 'server.500'));
    return ok(recap!);
  }

  @override
  Future<Result<StatusDashboard>> getDashboard({DriverId? driverId}) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<StatusDashboard?>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
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
}

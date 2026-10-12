import 'package:fpdart/fpdart.dart';
import '../../../../backend/contracts/status_dashboard_backend.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_guard.dart';
import '../../../../core/network/network_info.dart';
import '../../../../domain/duty_status/duty_status_code.dart';
import '../../../../domain/duty_status/status_dashboard.dart';
import '../../../../domain/duty_status/weekly_recap.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../domain/repositories/status_dashboard_repository.dart';

class StatusDashboardRepositoryImpl implements StatusDashboardRepository {
  final StatusDashboardBackend _backend;
  final NetworkInfo _networkInfo;

  /// Cache last known status dashboard to comply with FMCSA 49 CFR § 395.24
  /// (display remaining HOS and status continuously even when offline).
  StatusDashboard? _cachedDashboard;
  WeeklyRecap? _cachedRecap;

  Future<Either<Failure, StatusDashboard>>? _inFlightDashboard;

  StatusDashboardRepositoryImpl(this._backend, this._networkInfo);

  @override
  Future<Either<Failure, StatusDashboard>> getDashboard({DriverId? driverId}) async {
    if (_inFlightDashboard != null) {
      return _inFlightDashboard!;
    }
    final future = _fetchDashboard(driverId);
    _inFlightDashboard = future;
    try {
      return await future;
    } finally {
      _inFlightDashboard = null;
    }
  }

  Future<Either<Failure, StatusDashboard>> _fetchDashboard(DriverId? driverId) async {
    return guardedNetwork(_networkInfo, () async {
      final result = await _backend.getDashboard(driverId: driverId);
      return result.fold(
        (error) {
          if (_cachedDashboard != null) return Right(_cachedDashboard!);
          return Left(ServerFailure(
              message: error.code,
              statusCode: error.context?['statusCode'] as int?));
        },
        (data) {
          _cachedDashboard = data;
          return Right(data);
        },
      );
    }, offline: () async {
      final dashboard = _cachedDashboard ?? _defaultOfflineDashboard(driverId);
      _cachedDashboard = dashboard;
      return Right(dashboard);
    });
  }

  static StatusDashboard _defaultOfflineDashboard(DriverId? driverId) {
    return StatusDashboard(
      driver: DriverRef(
        id: driverId ?? const DriverId(0),
        name: '',
        displayText: '',
      ),
      operationalAlerts: const OperationalAlerts(
        toolIcon: false,
        warningTriangleIcon: false,
        connectionStatus: ConnectionStatus.disconnected,
      ),
      currentDutyStatus: DutyStatusCode.offDuty,
      remainingCircle: const RemainingCircle(
        remaining: Duration.zero,
        label: 'Remaining',
        progress: 0.0,
      ),
      hosIndicators: const HosIndicators(
        drive: HosIndicator(
          label: 'DRIVE',
          value: Duration(hours: 11),
          type: IndicatorType.remaining,
        ),
        shift: HosIndicator(
          label: 'SHIFT',
          value: Duration(hours: 14),
          type: IndicatorType.remaining,
        ),
        breakTime: HosIndicator(
          label: 'BREAK',
          value: Duration(hours: 8),
          type: IndicatorType.remaining,
        ),
        cycle: HosIndicator(
          label: 'CYCLE',
          value: Duration(hours: 70),
          type: IndicatorType.remaining,
        ),
      ),
      regulatoryConstraints: const RegulatoryConstraints(
        ruleSet: CycleRule.usa70_8,
        limits: ['11 hours driving', '14 hours on duty', '70 hours / 8 days'],
      ),
    );
  }

  static const WeeklyRecap _defaultOfflineRecap = WeeklyRecap(
    cycleRule: CycleRule.usa70_8,
    cycleUsed: Duration.zero,
    cycleRemaining: Duration(hours: 70),
    availableTomorrow: Duration(hours: 70),
    days: [],
  );

  @override
  Future<Either<Failure, StatusDashboard>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
  }) async {
    return guardedNetwork(_networkInfo, () async {
      final result = await _backend.updateDutyStatus(
        status: status,
        notes: notes,
      );
      return result.fold(
        (error) => Left(ServerFailure(
            message: error.code,
            statusCode: error.context?['statusCode'] as int?)),
        (data) {
          _cachedDashboard = data;
          return Right(data);
        },
      );
    }, offline: () async {
      final base = _cachedDashboard ?? _defaultOfflineDashboard(null);
      final updated = base.copyWith(
        currentDutyStatus: status,
        remainingCircle: _circleForStatus(status),
      );
      _cachedDashboard = updated;
      return Right(updated);
    });
  }

  static RemainingCircle _circleForStatus(DutyStatusCode status) {
    if (status == DutyStatusCode.offDuty ||
        status == DutyStatusCode.sleeperBerth ||
        status == DutyStatusCode.personalConveyance) {
      return const RemainingCircle(
        remaining: Duration.zero,
        label: 'Remaining',
        progress: 0.0,
      );
    }
    if (status == DutyStatusCode.driving) {
      const remaining = Duration(minutes: 35);
      const total = Duration(hours: 11);
      return RemainingCircle(
        remaining: remaining,
        label: 'Remaining',
        progress: (total.inMinutes - remaining.inMinutes) / total.inMinutes,
      );
    }
    const remaining = Duration(hours: 2, minutes: 8);
    const total = Duration(hours: 14);
    return RemainingCircle(
      remaining: remaining,
      label: 'Remaining',
      progress: (total.inMinutes - remaining.inMinutes) / total.inMinutes,
    );
  }

  @override
  Future<Either<Failure, WeeklyRecap>> getWeeklyRecap({DriverId? driverId}) async {
    return guardedNetwork(_networkInfo, () async {
      final result = await _backend.getWeeklyRecap(driverId: driverId);
      return result.fold(
        (error) {
          if (_cachedRecap != null) return Right(_cachedRecap!);
          return Left(ServerFailure(
              message: error.code,
              statusCode: error.context?['statusCode'] as int?));
        },
        (data) {
          _cachedRecap = data;
          return Right(data);
        },
      );
    }, offline: () async {
      return Right(_cachedRecap ?? _defaultOfflineRecap);
    });
  }
}

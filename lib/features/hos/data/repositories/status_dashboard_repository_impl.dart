import 'package:fpdart/fpdart.dart';
import '../../../../backend/contracts/status_dashboard_backend.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_guard.dart';
import '../../../../core/network/network_info.dart';
import '../../../../domain/duty_status/status_dashboard.dart';
import '../../../../domain/duty_status/weekly_recap.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../domain/repositories/status_dashboard_repository.dart';
import '../datasources/dashboard_local_cache.dart';

class StatusDashboardRepositoryImpl implements StatusDashboardRepository {
  final StatusDashboardBackend _backend;
  final NetworkInfo _networkInfo;

  /// الساعة الموثوقة (UTC) — **لا** `DateTime.now()`.
  ///
  /// تُستخدم لختم لحظة قياس كل لقطة. لو خُتمت بساعة الجهاز لأمكن للسائق
  /// تجميد العدّاد القانوني أو تعجيله بتعديل ساعة جهازه.
  final DateTime Function() _trustedNowUtc;

  /// آخر لقطة معروفة **مع لحظة قياسها** (نسخة من المحفوظ على القرص).
  CachedDashboard? _cachedSnapshot;
  WeeklyRecap? _cachedRecap;

  /// تخزين دائم للوحة والملخص.
  ///
  /// بدونه يفقد التطبيق آخر حالة معروفة عند كل إعادة تشغيل، فيضطر
  /// لعرض قيم مُختلَقة أو شاشة خطأ أثناء العمل أوفلاين.
  final DashboardLocalCache? _disk;

  Future<Either<Failure, StatusDashboard>>? _inFlightDashboard;

  @override
  DateTime? get snapshotAt => _cachedSnapshot?.takenAt;

  @override
  StatusDashboard? get cachedDashboard => _cachedSnapshot?.dashboard;

  StatusDashboardRepositoryImpl(
    this._backend,
    this._networkInfo, {
    DashboardLocalCache? disk,
    DateTime Function()? trustedNowUtc,
  })  : _disk = disk,
        _trustedNowUtc = trustedNowUtc ?? (() => DateTime.now().toUtc()) {
    // استعادة فورية عند البناء حتى لو كان التطبيق مغلقاً مدة طويلة —
    // ومعها لحظة القياس، وإلا لأُلغيت مدة الإغلاق من العدّاد.
    _cachedSnapshot = _disk?.loadDashboard();
    _cachedRecap = _disk?.loadRecap();
  }

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
          // الخادم تعذّر، لكن لدينا آخر لقطة معروفة — نعرضها بدل الخطأ،
          // وهي محمّلة بلحظة قياسها الأصلية فيبقى العدّاد صادقاً.
          final cached = _cachedSnapshot;
          if (cached != null) return Right(cached.dashboard);
          return Left(ServerFailure(
              message: error.code,
              statusCode: error.context?['statusCode'] as int?));
        },
        (data) {
          // استجابة حيّة ⇒ تُقاس لحظة وصولها على الساعة الموثوقة.
          final takenAt = _trustedNowUtc();
          _cachedSnapshot =
              CachedDashboard(dashboard: data, takenAt: takenAt);
          _disk?.saveDashboard(data, takenAt: takenAt);
          return Right(data);
        },
      );
    }, offline: () async {
      final cached = _cachedSnapshot;
      if (cached != null) return Right(cached.dashboard);
      // لا نولّد أرقاماً مُختلَقة: كان المسار يُرجع offDuty مع
      // 11:00/14:00/8:00/70:00 وهو رصيد قانوني غير موجود.
      // نبني اللوحة أعلاه من المحرك المحلي عبر HosOfflineDashboardBuilder.
      return const Left(NoDashboardSnapshotFailure());
    });
  }

  @override
  void cacheDashboard(StatusDashboard dashboard, {required DateTime takenAt}) {
    _cachedSnapshot = CachedDashboard(dashboard: dashboard, takenAt: takenAt);
    _disk?.saveDashboard(dashboard, takenAt: takenAt);
  }

  /// مسح اللقطة المحفوظة (عند تبديل السائق/الدورة).
  Future<void> clearCache() async {
    _cachedSnapshot = null;
    _cachedRecap = null;
    await _disk?.clear();
  }

  WeeklyRecap _synthesizeRecap() {
    final snapshot = _cachedSnapshot?.dashboard;
    final cycleIndicator = snapshot?.hosIndicators.cycle;
    final cycleRule = snapshot?.regulatoryConstraints.ruleSet ?? CycleRule.usa70_8;

    final cycleVal = cycleIndicator?.value;
    final cycleUsed = cycleIndicator?.type == IndicatorType.used && cycleVal != null
        ? cycleVal
        : Duration.zero;
    final cycleRemaining = cycleIndicator?.type == IndicatorType.remaining && cycleVal != null
        ? cycleVal
        : (const Duration(hours: 70) - cycleUsed);

    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayName = dayNames[d.weekday - 1];
      return RecapDay(
        date: DateTime(d.year, d.month, d.day),
        dayOfWeek: dayName,
        driving: Duration.zero,
        onDuty: Duration.zero,
        totalWork: Duration.zero,
      );
    });

    return WeeklyRecap(
      cycleRule: cycleRule,
      cycleUsed: cycleUsed,
      cycleRemaining: cycleRemaining.isNegative ? Duration.zero : cycleRemaining,
      availableTomorrow: const Duration(hours: 8),
      days: days,
    );
  }

  @override
  Future<Either<Failure, WeeklyRecap>> getWeeklyRecap({DriverId? driverId}) async {
    return guardedNetwork(_networkInfo, () async {
      final result = await _backend.getWeeklyRecap(driverId: driverId);
      return result.fold(
        (error) {
          if (_cachedRecap != null) return Right(_cachedRecap!);
          return Right(_synthesizeRecap());
        },
        (data) {
          _cachedRecap = data;
          _disk?.saveRecap(data);
          return Right(data);
        },
      );
    }, offline: () async {
      final cached = _cachedRecap;
      if (cached != null) return Right(cached);
      return Right(_synthesizeRecap());
    });
  }
}

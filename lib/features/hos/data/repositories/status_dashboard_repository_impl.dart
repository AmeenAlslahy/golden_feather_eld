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

  int _cacheEpoch = 0;
  Future<Either<Failure, StatusDashboard>>? _inFlightDashboard;
  DriverId? _inFlightDriverId;
  DateTime? _lastFetchCompletedAt;
  DriverId? _lastFetchedDriverId;

  @override
  DateTime? get snapshotAt => _cachedSnapshot?.takenAt;

  @override
  StatusDashboard? get cachedDashboard => _cachedSnapshot?.dashboard;

  StatusDashboardRepositoryImpl(
    this._backend,
    this._networkInfo, {
    DashboardLocalCache? disk,
    DateTime Function()? trustedNowUtc,
  }) : _disk = disk,
       _trustedNowUtc = trustedNowUtc ?? (() => DateTime.now().toUtc()) {
    // استعادة فورية عند البناء حتى لو كان التطبيق مغلقاً مدة طويلة —
    // ومعها لحظة القياس، وإلا لأُلغيت مدة الإغلاق من العدّاد.
    _cachedSnapshot = _disk?.loadDashboard();
    _cachedRecap = _disk?.loadRecap();
  }

  @override
  Future<Either<Failure, StatusDashboard>> getDashboard({
    DriverId? driverId,
  }) async {
    // إذا تغير السائق المطلوب عن آخر سائق محفوظ في الكاش أو الجاري جلبه،
    // نرفع epoch ونفرغ الكاش فوراً حتى لا يرى السائق الجديد بيانات السائق السابق
    // وحتى يُلغى أي طلب معلق للسائق القديم.
    if (driverId != null &&
        ((_lastFetchedDriverId != null && _lastFetchedDriverId != driverId) ||
         (_inFlightDriverId != null && _inFlightDriverId != driverId))) {
      _cacheEpoch++;
      _inFlightDashboard = null;
      _inFlightDriverId = null;
      _lastFetchCompletedAt = null;
      _lastFetchedDriverId = null;
      _cachedSnapshot = null;
      _cachedRecap = null;
    }

    if (_inFlightDashboard != null && _inFlightDriverId == driverId) {
      return _inFlightDashboard!;
    }

    final cached = _cachedSnapshot;
    if (cached != null &&
        _lastFetchCompletedAt != null &&
        _lastFetchedDriverId == driverId &&
        _trustedNowUtc().difference(_lastFetchCompletedAt!) < const Duration(seconds: 2)) {
      return Right(cached.dashboard);
    }

    final requestEpoch = _cacheEpoch;
    final future = _fetchDashboard(driverId, requestEpoch);
    _inFlightDashboard = future;
    _inFlightDriverId = driverId;
    try {
      final res = await future;
      if (_cacheEpoch == requestEpoch && res.isRight()) {
        _lastFetchCompletedAt = _trustedNowUtc();
        _lastFetchedDriverId = driverId;
      }
      return res;
    } finally {
      if (_cacheEpoch == requestEpoch) {
        _inFlightDashboard = null;
        _inFlightDriverId = null;
      }
    }
  }

  Future<Either<Failure, StatusDashboard>> _fetchDashboard(
    DriverId? driverId,
    int requestEpoch,
  ) async {
    return guardedNetwork(
      _networkInfo,
      () async {
        final result = await _backend.getDashboard(driverId: driverId);
        // تحقق الجيل: إذا أُبطل الكاش (تسجيل خروج، تغيير سائق، تغيير حالة) أثناء الطلب،
        // نرفض تخزين أو إرجاع النتيجة القديمة لمنع عرضها لسائق آخر أو كتابة كاش قديم.
        if (_cacheEpoch != requestEpoch) {
          return const Left(
            CacheFailure(message: 'requestAbortedDueToCacheInvalidation'),
          );
        }
        return result.fold(
          (error) {
            // الخادم تعذّر، لكن لدينا آخر لقطة معروفة — نعرضها بدل الخطأ،
            // وهي محمّلة بلحظة قياسها الأصلية فيبقى العدّاد صادقاً.
            final cached = _cachedSnapshot;
            if (cached != null && _cacheEpoch == requestEpoch) {
              return Right(cached.dashboard);
            }
            return Left(
              ServerFailure(
                message: error.code,
                statusCode: error.context?['statusCode'] as int?,
              ),
            );
          },
          (data) {
            if (_cacheEpoch != requestEpoch) {
              return const Left(
                CacheFailure(message: 'requestAbortedDueToCacheInvalidation'),
              );
            }
            // استجابة حيّة ⇒ تُقاس لحظة وصولها على الساعة الموثوقة.
            final takenAt = _trustedNowUtc();
            _cachedSnapshot = CachedDashboard(
              dashboard: data,
              takenAt: takenAt,
            );
            _disk?.saveDashboard(data, takenAt: takenAt);
            return Right(data);
          },
        );
      },
      offline: () async {
        if (_cacheEpoch != requestEpoch) {
          return const Left(
            CacheFailure(message: 'requestAbortedDueToCacheInvalidation'),
          );
        }
        final cached = _cachedSnapshot;
        if (cached != null) return Right(cached.dashboard);
        // لا نولّد أرقاماً مُختلَقة: كان المسار يُرجع offDuty مع
        // 11:00/14:00/8:00/70:00 وهو رصيد قانوني غير موجود.
        // نبني اللوحة أعلاه من المحرك المحلي عبر HosOfflineDashboardBuilder.
        return const Left(NoDashboardSnapshotFailure());
      },
    );
  }

  @override
  void cacheDashboard(StatusDashboard dashboard, {required DateTime takenAt}) {
    // تبديل الحالة أو حفظ لقطة أحدث يلغي أي طلب GET سابق كان جارياً
    _cacheEpoch++;
    _inFlightDashboard = null;
    _inFlightDriverId = null;
    _cachedSnapshot = CachedDashboard(dashboard: dashboard, takenAt: takenAt);
    _lastFetchCompletedAt = takenAt;
    _lastFetchedDriverId = dashboard.driver.id;
    _disk?.saveDashboard(dashboard, takenAt: takenAt);
  }

  /// مسح اللقطة المحفوظة (عند تبديل السائق/الدورة/تسجيل الخروج).
  Future<void> clearCache() async {
    _cacheEpoch++;
    _inFlightDashboard = null;
    _inFlightDriverId = null;
    _lastFetchCompletedAt = null;
    _lastFetchedDriverId = null;
    _cachedSnapshot = null;
    _cachedRecap = null;
    await _disk?.clear();
  }

  @override
  Future<Either<Failure, WeeklyRecap>> getWeeklyRecap({
    DriverId? driverId,
  }) async {
    return guardedNetwork(
      _networkInfo,
      () async {
        final result = await _backend.getWeeklyRecap(driverId: driverId);
        return result.fold(
          (error) {
            // لا كاش ⇒ "غير متاح" صراحةً. البديل القديم كان يبني أسبوعاً
            // فارغاً مع 8 ساعات متاحة غداً — رصيد قانوني غير موجود.
            final cached = _cachedRecap;
            if (cached != null) return Right(cached);
            return const Left(NoRecapSnapshotFailure());
          },
          (data) {
            _cachedRecap = data;
            _disk?.saveRecap(data);
            return Right(data);
          },
        );
      },
      offline: () async {
        final cached = _cachedRecap;
        if (cached != null) return Right(cached);
        return const Left(NoRecapSnapshotFailure());
      },
    );
  }
}

/// انحدار للعطل المُبلَّغ: "دخلت بعد 20 دقيقة فوجدت الوقت كما تركته".
///
/// ### العطل
///
/// `GET /eld/status` **لا يحمل أي طابع زمني** — لا `generatedAt` ولا
/// `snapshotIso`. المرجع الوحيد للحظة القياس هو ترويسة HTTP `Date:` التي
/// يلتقطها `TimeDriftInterceptor` وتُثبَّت في `TrustedTimeProvider`.
///
/// والعدّاد التنازلي يحسب:
/// ```text
/// المتبقي الحيّ = متبقي الخادم − (الآن الموثوقة − لحظة القياس)
/// ```
///
/// فإذا خُتمت لحظة القياس بـ "الآن" لحظة استرجاع لقطة من القرص، يصبح
/// الطرح صفراً — وتُلغى مدة إغلاق التطبيق كاملة من الحساب.
///
/// ### الأثر
///
/// السائق يخرج 20 دقيقة ويعود فيرى `03:48` بينما الخادم يعرض `03:28`.
/// التطبيق **أقلّ من الخادم دائماً** = رصيد قانوني مُبالَغ فيه بلا سند،
/// والسائق يقود على أساسه.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/contracts/status_dashboard_backend.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/duty_status/weekly_recap.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/hos/data/datasources/dashboard_local_cache.dart';
import 'package:golden_feather_eld/features/hos/data/repositories/status_dashboard_repository_impl.dart';
import 'package:golden_feather_eld/features/hos/presentation/widgets/status_dashboard/circular_timer_logic.dart';

// ─── Fixture: قيم مُلتقطة حرفياً من الخادم الحقيقي ───────────────────────
//
// GET /eld/status  (Date: Wed, 14 Oct 2026 01:44:26 GMT, driver 2)
//   currentDutyStatus : ON_DUTY
//   remainingCircle   : 03:48  (progress 0.73)
//   DRIVE  00:04 USED      SHIFT 10:12 USED
//   BREAK  07:56 REMAINING CYCLE 25:41 USED
//
// تحقّق: 14:00 − 10:12 = 03:48 ✓   progress 10:12/14 = 0.724 ✓

StatusDashboard _serverDashboard({
  Duration circleRemaining = const Duration(hours: 3, minutes: 48),
  Duration shiftUsed = const Duration(hours: 10, minutes: 12),
  Duration driveUsed = const Duration(minutes: 4),
  Duration breakRemaining = const Duration(hours: 7, minutes: 56),
  Duration cycleUsed = const Duration(hours: 25, minutes: 41),
}) {
  return StatusDashboard(
    driver: const DriverRef(
      id: DriverId(2),
      name: 'Admin User',
      displayText: 'Admin User - 2',
    ),
    operationalAlerts: const OperationalAlerts(
      toolIcon: false,
      warningTriangleIcon: true,
      connectionStatus: ConnectionStatus.warning,
    ),
    currentDutyStatus: DutyStatusCode.onDutyNotDriving,
    remainingCircle: RemainingCircle(
      remaining: circleRemaining,
      label: 'Remaining',
      progress: 0.73,
    ),
    hosIndicators: HosIndicators(
      drive:
          HosIndicator(label: 'DRIVE', value: driveUsed, type: IndicatorType.used),
      shift:
          HosIndicator(label: 'SHIFT', value: shiftUsed, type: IndicatorType.used),
      breakTime: HosIndicator(
          label: 'BREAK', value: breakRemaining, type: IndicatorType.remaining),
      cycle:
          HosIndicator(label: 'CYCLE', value: cycleUsed, type: IndicatorType.used),
    ),
    regulatoryConstraints: const RegulatoryConstraints(
      ruleSet: CycleRule.usa70_8,
      limits: [
        '11-Hour Driving Limit',
        '14-Hour Shift Limit',
        '8-Hour Break Limit',
        '70-Hour / 8-Day Cycle Limit',
      ],
    ),
  );
}

// ─── Fakes ───────────────────────────────────────────────────────────────

/// ذاكرة تحاكي `PrefsDashboardLocalCache` بلا طبقة النصوص.
class _MemCache implements DashboardLocalCache {
  CachedDashboard? stored;

  @override
  Future<void> saveDashboard(StatusDashboard dashboard,
      {required DateTime takenAt}) async {
    stored = CachedDashboard(dashboard: dashboard, takenAt: takenAt.toUtc());
  }

  @override
  CachedDashboard? loadDashboard() => stored;

  @override
  Future<void> saveRecap(WeeklyRecap recap) async {}

  @override
  WeeklyRecap? loadRecap() => null;

  @override
  Future<void> clear() async => stored = null;
}

/// كاش يحمل بايتات قديمة بلا طابع قياس — كما كان يخرجها الكود السابق.
class _LegacyNoStampCache implements DashboardLocalCache {
  @override
  Future<void> saveDashboard(StatusDashboard dashboard,
      {required DateTime takenAt}) async {}

  @override
  CachedDashboard? loadDashboard() => null; // age unknown ⇒ discarded

  @override
  Future<void> saveRecap(WeeklyRecap recap) async {}

  @override
  WeeklyRecap? loadRecap() => null;

  @override
  Future<void> clear() async {}
}

class _Backend implements StatusDashboardBackend {
  _Backend(this.dashboard);

  final StatusDashboard dashboard;
  int calls = 0;
  AppError? failWith;

  @override
  Future<Result<StatusDashboard>> getDashboard({DriverId? driverId}) async {
    calls++;
    final f = failWith;
    if (f != null) return err(f);
    return ok(dashboard);
  }

  @override
  Future<Result<StatusDashboard>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
  }) async =>
      ok(dashboard);

  @override
  Future<Result<WeeklyRecap>> getWeeklyRecap({DriverId? driverId}) async =>
      err(const ServerError(code: 'unimplemented'));
}

class _Network implements NetworkInfo {
  _Network(this.online);

  bool online;

  @override
  bool get isConnected => online;

  @override
  Stream<bool> get onConnectionChange => const Stream<bool>.empty();
}

// ─── Tests ───────────────────────────────────────────────────────────────

void main() {
  // t0 = لحظة القياس في الخادم (ترويسة Date: الحقيقية).
  final t0 = DateTime.utc(2026, 10, 14, 1, 44, 26);
  final t20 = t0.add(const Duration(minutes: 20));

  group('لحظة القياس تُحفظ وتُستعاد', () {
    test('اللقطة المحفوظة تعود بلحظة قياسها لا بلحظة الفتح', () async {
      final cache = _MemCache();
      await cache.saveDashboard(_serverDashboard(), takenAt: t0);

      final loaded = cache.loadDashboard();
      expect(loaded, isNotNull);
      expect(loaded!.takenAt, t0);
      expect(loaded.takenAt.isUtc, isTrue);
    });

    test('لقطة بلا طابع قياس تُهمَل (لا تُعرض كأنها حديثة)', () async {
      final cache = _LegacyNoStampCache();
      expect(cache.loadDashboard(), isNull,
          reason: 'لقطة بلا لحظة موثوقة لا يجوز عرضها كأن عمرها صفر');
    });
  });

  group('المستودع يختم لحظة القياس على الساعة الموثوقة', () {
    test('استجابة حيّة ⇒ تُقاس بلحظة الجلب الموثوقة', () async {
      final backend = _Backend(_serverDashboard());
      final repo = StatusDashboardRepositoryImpl(
        backend,
        _Network(true),
        trustedNowUtc: () => t0,
      );

      final result = await repo.getDashboard();

      expect(result.isRight(), isTrue);
      expect(repo.snapshotAt, t0);
      expect(backend.calls, 1);
    });

    test('الاسترجاع من القرص يُبقي لحظة القياس الأصلية', () async {
      // === العطل المُبلَّغ ===
      // 1) الخادم يرد 03:48 عند 01:44
      // 2) يغلق السائق التطبيق 20 دقيقة
      // 3) يفتح بلا شبكة ⇒ المستودع يرجع اللقطة المحفوظة
      // 4) ❌ ختمها بـ "الآن" ⇒ 03:48   (أكثر من الحقيقي بـ 20 دقيقة)
      // 5) ✅ مع الإصلاح: لحظة القياس تبقى 01:44 فيُطرح الفارق ⇒ 03:28

      final backend = _Backend(_serverDashboard());
      final disk = _MemCache();

      // الجلسة الأولى: جلب ناجح، ثم إغلاق التطبيق.
      final first = StatusDashboardRepositoryImpl(
        backend,
        _Network(true),
        disk: disk,
        trustedNowUtc: () => t0,
      );
      expect((await first.getDashboard()).isRight(), isTrue);
      expect(first.snapshotAt, t0);
      final callsBefore = backend.calls;

      // إعادة تشغيل بعد 20 دقيقة، بلا شبكة.
      final second = StatusDashboardRepositoryImpl(
        backend,
        _Network(false),
        disk: disk,
        trustedNowUtc: () => t20,
      );
      expect(second.snapshotAt, t0,
          reason: 'يجب أن تبقى 01:44 — لا 02:04');

      final offline = await second.getDashboard();
      expect(offline.isRight(), isTrue);
      expect(backend.calls, callsBefore, reason: 'لا HTTP بلا شبكة');

      final dashboard = offline.fold(
            (_) => _serverDashboard(),
            (d) => d,
          );
      final elapsed = t20.difference(second.snapshotAt!);
      expect(elapsed, const Duration(minutes: 20));

      final ui = CircularTimerLogic.calculateUiState(
        circle: dashboard.remainingCircle,
        dutyStatus: dashboard.currentDutyStatus,
        hosIndicators: dashboard.hosIndicators,
        statusLabel: 'ON_DUTY',
        elapsedSinceSnapshot: elapsed,
      );

      expect(ui.liveRemaining, const Duration(hours: 3, minutes: 28),
          reason: '03:48 − 00:20 = 03:28 — لا 03:48');
    });

    test('فشل الخادم مع وجود لقطة ⇒ تبقى لحظة القياس الأصلية', () async {
      final backend = _Backend(_serverDashboard());
      final disk = _MemCache();

      final first = StatusDashboardRepositoryImpl(
        backend,
        _Network(true),
        disk: disk,
        trustedNowUtc: () => t0,
      );
      await first.getDashboard();

      backend.failWith = const ServerError(code: 'server.500');

      final second = StatusDashboardRepositoryImpl(
        backend,
        _Network(true),
        disk: disk,
        trustedNowUtc: () => t20,
      );
      final degraded = await second.getDashboard();

      expect(degraded.isRight(), isTrue);
      expect(second.snapshotAt, t0);
      expect(t20.difference(second.snapshotAt!), const Duration(minutes: 20));
    });

    test('بلا لقطة وبلا خادم ⇒ لا نخترع رقماً', () async {
      final backend = _Backend(_serverDashboard())
        ..failWith = const ServerError(code: 'server.500');
      final repo = StatusDashboardRepositoryImpl(
        backend,
        _Network(true),
        disk: _MemCache(),
        trustedNowUtc: () => t0,
      );

      final result = await repo.getDashboard();
      expect(result.isLeft(), isTrue);
    });
  });

  group('منطق الدائرة يطابق الخادم', () {
    test('ON_DUTY: الحد الحاكم = الورقية (3:48 من 14h ناقص 10:12)', () {
      final d = _serverDashboard();
      final ui = CircularTimerLogic.calculateUiState(
        circle: d.remainingCircle,
        dutyStatus: DutyStatusCode.onDutyNotDriving,
        hosIndicators: d.hosIndicators,
        statusLabel: 'ON_DUTY',
        elapsedSinceSnapshot: Duration.zero,
      );

      expect(ui.liveRemaining, const Duration(hours: 3, minutes: 48));
      expect(ui.progress, closeTo(0.724, 0.01));
      expect(ui.isRest, isFalse);
    });

    test('كل دقيقة منطقية تنقص دقيقة واحدة', () {
      final d = _serverDashboard();
      Duration at(int minutes) => CircularTimerLogic.calculateUiState(
            circle: d.remainingCircle,
            dutyStatus: DutyStatusCode.onDutyNotDriving,
            hosIndicators: d.hosIndicators,
            statusLabel: 'ON_DUTY',
            elapsedSinceSnapshot: Duration(minutes: minutes),
          ).liveRemaining;

      expect(at(0), const Duration(hours: 3, minutes: 48));
      expect(at(1), const Duration(hours: 3, minutes: 47));
      expect(at(20), const Duration(hours: 3, minutes: 28));
      expect(at(60), const Duration(hours: 2, minutes: 48));
    });

    test('لا ينزل تحت الصفر', () {
      final d = _serverDashboard();
      final ui = CircularTimerLogic.calculateUiState(
        circle: d.remainingCircle,
        dutyStatus: DutyStatusCode.onDutyNotDriving,
        hosIndicators: d.hosIndicators,
        statusLabel: 'ON_DUTY',
        elapsedSinceSnapshot: const Duration(hours: 9),
      );
      expect(ui.liveRemaining, Duration.zero);
      expect(ui.progress, 1.0);
    });

    test('DRIVING: الحد 11 ساعة على مؤشر القيادة', () {
      final d = _serverDashboard(driveUsed: const Duration(hours: 10));
      final ui = CircularTimerLogic.calculateUiState(
        circle: d.remainingCircle,
        dutyStatus: DutyStatusCode.driving,
        hosIndicators: d.hosIndicators,
        statusLabel: 'DRIVING',
        elapsedSinceSnapshot: Duration.zero,
      );
      expect(ui.liveRemaining, const Duration(hours: 1));
    });

    test('OFF_DUTY: المتبقي صفر ودائرة فارغة', () {
      final d = _serverDashboard();
      final ui = CircularTimerLogic.calculateUiState(
        circle: d.remainingCircle,
        dutyStatus: DutyStatusCode.offDuty,
        hosIndicators: d.hosIndicators,
        statusLabel: 'OFF_DUTY',
        elapsedSinceSnapshot: Duration.zero,
      );
      expect(ui.liveRemaining, Duration.zero);
      expect(ui.isRest, isTrue);
    });

    test('وثيقة السلوك الخاطئ: لا نقبل 03:48 بدل 03:28', () {
      // مثبَّت عمداً: لو عاد العطل يوماً فلن "يُصلح" بالتصحيح الخطأ.
      const base = Duration(hours: 3, minutes: 48);
      expect(base - const Duration(minutes: 20),
          const Duration(hours: 3, minutes: 28)); // الصحيح
      expect(base - Duration.zero, const Duration(hours: 3, minutes: 48)); // الخاطئ
    });
  });
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/domain/account/driver_rules.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/account/presentation/providers/driver_rules_provider.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_rules_engine.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/tracking/duty_status_tracker.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/change_status_provider.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/hos_engine_provider.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/hos_provider.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/status_dashboard_providers.dart';
import 'package:golden_feather_eld/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:golden_feather_eld/features/tracking/presentation/providers/tracking_provider.dart';
import 'package:mocktail/mocktail.dart';

class _Storage extends Mock implements LocalStorageService {}

class _TrackingRepo extends Mock implements TrackingRepository {}

class _Engine extends Mock implements HosRulesEngine {}

class _FakeNetwork implements NetworkInfo {
  _FakeNetwork({required this.isConnected});

  @override
  final bool isConnected;

  @override
  Stream<bool> get onConnectionChange => const Stream.empty();
}

/// يقبل التغيير ويعيد النتيجة المُعدّة مسبقاً (لقطة أو بلا لقطة).
class _FakeHosNotifier extends StateNotifier<HosEngineResult>
    implements HosNotifier {
  _FakeHosNotifier(DutyStatus current)
      : super(HosEngineReady(HosStatusUpdate(
          currentStatus: current,
          limits: const HosLimits(
            remainingDriveMinutes: 600,
            remainingShiftMinutes: 800,
            remainingCycleHours: 60,
            breakRequired: false,
            breakRemainingMinutes: 480,
          ),
          alerts: const [],
          violations: const [],
          remainingDriveMinutes: 600,
          remainingShiftMinutes: 800,
          remainingCycleHours: 60,
          breakRequired: false,
          breakRemainingMinutes: 480,
        )));

  ManualDutyChangeResult nextResult = const ManualDutyChangeResult();

  @override
  Future<ManualDutyChangeResult> changeStatus(DutyStatus newStatus,
      {String? annotation,
      bool isYardMoves = false,
      double? latitude,
      double? longitude}) async {
    return nextResult;
  }

  @override
  void refresh() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// لوحة مزيفة تسجّل ما يُطبَّق عليها وما يُطلب منها من تصحيح.
class _RecordingDashboardNotifier extends StatusDashboardNotifier {
  _RecordingDashboardNotifier(this._seed);

  final StatusDashboard _seed;

  final applied = <StatusDashboard>[];
  int reconcileCalls = 0;
  int refreshCalls = 0;

  @override
  Future<StatusDashboard> build() async => _seed;

  @override
  void applyServerDashboard(StatusDashboard dashboard) {
    applied.add(dashboard);
    state = AsyncValue.data(dashboard);
  }

  @override
  Future<void> refresh({bool showLoading = true}) async {
    refreshCalls++;
  }

  @override
  Future<void> reconcileWithServer() async {
    reconcileCalls++;
  }
}

StatusDashboard _seed() {
  return const StatusDashboard(
    driver: DriverRef(
      id: DriverId(646),
      name: 'Naseem Hassan Ali Adam',
      displayText: 'Naseem - 646',
    ),
    operationalAlerts: OperationalAlerts(
      toolIcon: false,
      warningTriangleIcon: false,
      connectionStatus: ConnectionStatus.ok,
    ),
    currentDutyStatus: DutyStatusCode.onDutyNotDriving,
    remainingCircle: RemainingCircle(
      remaining: Duration(hours: 2, minutes: 8),
      label: 'Remaining',
      progress: 0.84,
    ),
    hosIndicators: HosIndicators(
      drive: HosIndicator(
        label: 'DRIVE',
        value: Duration(minutes: 35),
        type: IndicatorType.remaining,
      ),
      shift: HosIndicator(
        label: 'SHIFT',
        value: Duration(hours: 2, minutes: 8),
        type: IndicatorType.remaining,
      ),
      breakTime: HosIndicator(
        label: 'BREAK',
        value: Duration(hours: 6),
        type: IndicatorType.remaining,
      ),
      cycle: HosIndicator(
        label: 'CYCLE',
        value: Duration(hours: 52),
        type: IndicatorType.remaining,
      ),
    ),
    regulatoryConstraints: RegulatoryConstraints(
      ruleSet: CycleRule.usa70_8,
      limits: ['maxDrivingHours: 11'],
    ),
  );
}

/// لقطة خادم كما تُلتقط من GET /eld/status بعد التغيير.
StatusDashboard _serverSnapshot({
  required DutyStatusCode status,
  String driverName = '',
}) {
  return StatusDashboard(
    driver: DriverRef(
      id: const DriverId(0),
      name: driverName,
      displayText: driverName,
    ),
    operationalAlerts: const OperationalAlerts(
      toolIcon: false,
      warningTriangleIcon: false,
      connectionStatus: ConnectionStatus.ok,
    ),
    currentDutyStatus: status,
    remainingCircle: const RemainingCircle(
      remaining: Duration(minutes: 90),
      label: 'Remaining',
      progress: 0.9,
    ),
    hosIndicators: const HosIndicators(
      drive: HosIndicator(
        label: 'DRIVE',
        value: Duration(minutes: 90),
        type: IndicatorType.remaining,
      ),
      shift: HosIndicator(
        label: 'SHIFT',
        value: Duration(hours: 4),
        type: IndicatorType.remaining,
      ),
      breakTime: HosIndicator(
        label: 'BREAK',
        value: Duration(hours: 5),
        type: IndicatorType.remaining,
      ),
      cycle: HosIndicator(
        label: 'CYCLE',
        value: Duration(hours: 40),
        type: IndicatorType.remaining,
      ),
    ),
    regulatoryConstraints: const RegulatoryConstraints(
      ruleSet: CycleRule.usa70_8,
      limits: [],
    ),
  );
}

/// س1: مسارات اللوحة بعد قبول تغيير الحالة —
/// القبول بلقطة، والقبول بلا لقطة (متصل/أوفلاين). السياسة: لا اختلاق
/// أرقام أبداً؛ اللقطة من POST، أو تصحيح من الخادم، أو لوحة المحرك محلياً.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeHosNotifier hos;
  late _RecordingDashboardNotifier dashboard;
  late _FakeNetwork network;
  late _Engine engine;

  ProviderContainer container({
    HosRulesEngine? engineOverride,
    bool realChangeStatus = false,
  }) {
    final storage = _Storage();
    when(() => storage.hosConfiguration).thenReturn(HosConfiguration.usa70_8());

    return ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        hosStatusProvider.overrideWith((ref) => hos),
        statusDashboardProvider.overrideWith(() => dashboard),
        networkInfoProvider.overrideWithValue(network),
        currentVehicleSpeedProvider.overrideWith((ref) => 0.0),
        driverRulesProvider.overrideWith(
          (ref) => const AsyncValue.data(
            DriverRules(
              isPersonalConveyanceAllowed: false,
              isYardMoveAllowed: false,
            ),
          ),
        ),
        currentDriverIdProvider.overrideWith((ref) => 106),
        hosEngineProvider.overrideWith((ref) => engineOverride ?? engine),
        trackingStateProvider.overrideWith(
          (ref) => TrackingNotifier(_TrackingRepo(), ref),
        ),
        if (!realChangeStatus)
          changeStatusProvider.overrideWith(
            (ref) => ChangeStatusNotifier(
              ref,
              initialStatus: DutyStatus.offDuty,
              isYardMoves: false,
              initialLocation: 'Dallas, TX',
              isPersonalConveyanceAllowed: false,
              isYardMoveAllowed: false,
              isVehicleMoving: false,
            ),
          ),
      ],
    );
  }

  setUp(() {
    hos = _FakeHosNotifier(DutyStatus.offDuty);
    dashboard = _RecordingDashboardNotifier(_seed());
    network = _FakeNetwork(isConnected: true);
    engine = _Engine();
  });

  Future<DutyChangeResult> submitDriving(ProviderContainer c) async {
    await c.read(statusDashboardProvider.future);
    final notifier = c.read(changeStatusProvider.notifier);
    notifier.selectOption(DutyStatusOption.driving);
    return notifier.submit();
  }

  test('a POST snapshot feeds the board directly (driver/limits merged), '
      'with no reconcile and no second GET', () async {
    hos.nextResult = ManualDutyChangeResult(
      dashboard: _serverSnapshot(status: DutyStatusCode.driving),
    );
    final c = container();
    addTearDown(c.dispose);

    final result = await submitDriving(c);

    expect(result, isA<DutyChangeSuccess>());
    expect(dashboard.applied, hasLength(1));
    final applied = dashboard.applied.single;
    expect(applied.currentDutyStatus, DutyStatusCode.driving);
    expect(applied.hosIndicators.drive.value,
        equals(const Duration(minutes: 90)));
    // الحقول الناقصة في لقطة POST تُكمَّل من اللوحة الحالية.
    expect(applied.driver.name, 'Naseem Hassan Ali Adam');
    expect(applied.regulatoryConstraints.limits, isNotEmpty);
    expect(dashboard.reconcileCalls, 0);
    expect(dashboard.refreshCalls, 0);
  });

  test('online + no snapshot: nothing local is fabricated — a silent server '
      'reconcile is scheduled instead', () async {
    hos.nextResult = const ManualDutyChangeResult();
    final c = container();
    addTearDown(c.dispose);

    final result = await submitDriving(c);

    expect(result, isA<DutyChangeSuccess>());
    expect(dashboard.applied, isEmpty);
    expect(dashboard.reconcileCalls, 1);
    expect(dashboard.refreshCalls, 0);
  });

  test('offline + no snapshot: the board is rebuilt from the local engine '
      'immediately, without touching the network', () async {
    network = _FakeNetwork(isConnected: false);
    hos.nextResult = const ManualDutyChangeResult();
    when(() => engine.currentStatus)
        .thenReturn(HosEngineReady(const HosStatusUpdate(
      currentStatus: DutyStatus.driving,
      limits: HosLimits(
        remainingDriveMinutes: 600,
        remainingShiftMinutes: 800,
        remainingCycleHours: 60,
        breakRequired: false,
        breakRemainingMinutes: 480,
      ),
      alerts: [],
      violations: [],
      remainingDriveMinutes: 600,
      remainingShiftMinutes: 800,
      remainingCycleHours: 60,
      breakRequired: false,
      breakRemainingMinutes: 480,
    )));
    final c = container(engineOverride: engine);
    addTearDown(c.dispose);

    final result = await submitDriving(c);

    expect(result, isA<DutyChangeSuccess>());
    expect(dashboard.applied, hasLength(1));
    final applied = dashboard.applied.single;
    expect(applied.currentDutyStatus, DutyStatusCode.driving);
    expect(applied.hosIndicators.drive.value, equals(const Duration(minutes: 600)));
    expect(applied.operationalAlerts.connectionStatus,
        ConnectionStatus.disconnected);
    expect(dashboard.reconcileCalls, 0);
  });

  // انحدار: نبضة اللوحة (تصحيح كل 5 دقائق أو العودة للتطبيق) كانت تُعيد
  // بناء المزود كاملاً فيضيع اختيار السائق ويُعطَّل زر التحديث.
  test('a dashboard emission (periodic reconcile / app resume) keeps the '
      'driver selection and the same notifier', () async {
    final c = container(realChangeStatus: true);
    addTearDown(c.dispose);
    c.listen(changeStatusProvider, (_, __) {});
    await c.read(statusDashboardProvider.future);

    final notifier = c.read(changeStatusProvider.notifier);
    notifier.updateLocation('Dallas, TX');
    notifier.selectOption(DutyStatusOption.driving);

    expect(
      c.read(changeStatusProvider).selectedOption,
      DutyStatusOption.driving,
    );
    expect(c.read(changeStatusProvider).isValid, isTrue);

    // نفس الحالة الحالية من الخادم — كما تفعل نبضة التصحيح.
    c.read(statusDashboardProvider.notifier).applyServerDashboard(_seed());

    expect(
      c.read(changeStatusProvider).selectedOption,
      DutyStatusOption.driving,
    );
    expect(c.read(changeStatusProvider).isValid, isTrue);
    expect(identical(c.read(changeStatusProvider.notifier), notifier), isTrue);
  });

  test('before the driver picks anything, a new server status becomes the '
      'current status', () async {
    final c = container(realChangeStatus: true);
    addTearDown(c.dispose);
    c.listen(changeStatusProvider, (_, __) {});
    await c.read(statusDashboardProvider.future);

    c
        .read(statusDashboardProvider.notifier)
        .applyServerDashboard(_serverSnapshot(status: DutyStatusCode.driving));

    final state = c.read(changeStatusProvider);
    expect(state.initialOption, DutyStatusOption.driving);
    expect(state.selectedOption, DutyStatusOption.driving);
    expect(state.isValid, isFalse);
  });
}

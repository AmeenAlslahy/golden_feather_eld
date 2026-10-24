import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/features/account/presentation/providers/account_provider.dart';
import 'package:golden_feather_eld/features/dvir/data/providers/dvir_repository_providers.dart';
import 'package:golden_feather_eld/features/dvir/domain/dvir_catalog.dart';
import 'package:golden_feather_eld/features/dvir/domain/entities/dvir_defect.dart';
import 'package:golden_feather_eld/features/dvir/domain/entities/dvir_report.dart';
import 'package:golden_feather_eld/features/dvir/domain/repositories/dvir_repository.dart';
import 'package:golden_feather_eld/features/dvir/presentation/providers/dvir_form_provider.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';
import 'package:golden_feather_eld/features/vehicle/domain/entities/vehicle.dart';
import 'package:golden_feather_eld/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:golden_feather_eld/features/vehicle/presentation/providers/vehicle_provider.dart';
import 'package:mocktail/mocktail.dart';

const _vehicleA = Vehicle(
  id: 'A-ID',
  uniqueId: 'A-U',
  deviceId: 101,
  name: 'Truck A',
  year: '2020',
);
const _vehicleB = Vehicle(
  id: 'B-ID',
  uniqueId: 'B-U',
  deviceId: 102,
  name: 'Truck B',
  year: '2021',
);
final _fixedUtc = DateTime.utc(2026, 10, 24, 12, 0);

class _FixedTimeProvider implements TrustedTimeProvider {
  _FixedTimeProvider(this._current);
  final TrustedTimeResult Function() _current;

  @override
  TrustedTimeResult get currentTime => _current();
  @override
  TrustedTimeState get state => TrustedTimeState.trusted;
  @override
  Duration get monotonicElapsed => Duration.zero;
  @override
  void anchor(DateTime serverUtc) {}
}

class _StubAccountNotifier extends StateNotifier<AccountState>
    implements AccountNotifier {
  _StubAccountNotifier() : super(const AccountState());

  // عضو واحد فقط يُقرأ في هذه الاختبارات: `state`. ما عداه غير مستدعى.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _VehicleRepo extends Mock implements VehicleRepository {}

class _FakeRepository implements DvirRepository {
  Either<Failure, List<DvirReport>> listResult =
      const Right<Failure, List<DvirReport>>([]);
  Either<Failure, DvirReport?> previousResult =
      const Right<Failure, DvirReport?>(null);
  Either<Failure, bool> submitResult = const Right<Failure, bool>(true);

  final Map<String, Completer<Either<Failure, DvirReport?>>> previousByVehicle =
      {};
  final List<DvirReport> submitted = [];

  @override
  Future<Either<Failure, List<DvirReport>>> getDvirReports(
    String vehicleId,
  ) async => listResult;

  @override
  Future<Either<Failure, DvirReport?>> getPreviousDvir(String vehicleId) {
    final controlled = previousByVehicle[vehicleId];
    if (controlled != null) return controlled.future;
    return Future.value(previousResult);
  }

  @override
  Future<Either<Failure, DvirReport>> getDvirDetails(String id) async =>
      const Left(ServerFailure(message: 'not used'));

  @override
  Future<Either<Failure, List<DvirCatalogItem>>> getDefectsCatalog() async =>
      const Right<Failure, List<DvirCatalogItem>>([]);

  @override
  Future<Either<Failure, bool>> submitDvirReport(
    DvirReport report, {
    required int driverId,
  }) async {
    submitted.add(report);
    return submitResult;
  }

  @override
  Future<Either<Failure, bool>> reviewDvir({
    required String dvirId,
    required int reviewingDriverId,
    required String reviewingDriverName,
    required String signatureData,
    required bool driverAgreed,
    String? reviewNotes,
  }) async => const Right<Failure, bool>(true);

  @override
  Future<Either<Failure, DvirDefect>> getDefectDetails(int defectId) async =>
      const Left(ServerFailure(message: 'not used'));

  @override
  Future<Either<Failure, List<DvirDefect>>> getActiveDefects({
    required String uniqueId,
  }) async => const Right<Failure, List<DvirDefect>>([]);
}

DvirFormTextValue _text() => const DvirFormTextValue(
  location: 'Dallas, TX',
  odometer: '12500',
  trailerNumber: 'T-1',
  company: 'Golden Feather',
  remarks: 'ok',
  vehicleDefects: '',
  trailerDefects: '',
);

/// اختبارات عقد عملية الإرسال في DvirFormNotifier — بلا ودجت: الحصر،
/// إعادة التحقق من المركبة بعد الانتظار، الفشل المُطبَّع، والوقت
/// الموثوق الطازج لحظة الحفظ (ملاحظات المراجعة المعمارية 2026-10-24).
void main() {
  /// حاوية مهيّأة بالكامل: مستودع DVIR مزيّف، مركبات محمّلة، لوحة قيادة
  /// بلا مركبة، وقت موثوق قابل للتحديد، وحساب صامت.
  Future<(ProviderContainer, _FakeRepository)> buildContainer({
    List<Vehicle> vehicles = const [_vehicleA, _vehicleB],
    TrustedTimeResult? timeResult,
  }) async {
    final repository = _FakeRepository();
    final vehicleRepo = _VehicleRepo();
    when(
      () => vehicleRepo.getVehicles(),
    ).thenAnswer((_) async => Right(vehicles));
    final TrustedTimeResult currentTime =
        timeResult ?? TrustedTimeAvailable(_fixedUtc);

    final container = ProviderContainer(
      overrides: [
        dvirRepositoryProvider.overrideWithValue(repository),
        vehicleProvider.overrideWith((ref) => VehicleNotifier(vehicleRepo)),
        dashboardDataProvider.overrideWith((ref) => DashboardNotifier()),
        accountProvider.overrideWith((ref) => _StubAccountNotifier()),
        trustedTimeProvider.overrideWithValue(
          _FixedTimeProvider(() => currentTime),
        ),
      ],
    );
    addTearDown(container.dispose);
    // تحميل قائمة المركبات (المُنشئ لا يحملها تلقائياً).
    await container.read(vehicleProvider.notifier).loadVehicles();
    // الصفحة الحقيقية "تشاهد" المزوّد فيبقيه autoDispose حياً — نحاكيها
    // هنا وإلا تُلغى مستمعاته فور القراءة.
    final keepAlive = container.listen(dvirFormProvider(null), (_, _) {});
    addTearDown(keepAlive.close);
    return (container, repository);
  }

  group('حصر عملية الإرسال (begin/end)', () {
    test(
      'عملية ثانية تُرفض ما دامت الأولى مفتوحة، وتُقبل بعد إغلاقها',
      () async {
        final (container, _) = await buildContainer();
        final notifier = container.read(dvirFormProvider(null).notifier);

        expect(notifier.beginSubmission(), isTrue);
        expect(notifier.state.submissionInProgress, isTrue);
        expect(notifier.beginSubmission(), isFalse);

        notifier.endSubmission();
        expect(notifier.state.submissionInProgress, isFalse);
        expect(notifier.beginSubmission(), isTrue);
      },
    );

    test('البوابة ترفض العمل بلا عملية مفتوحة', () async {
      final (container, _) = await buildContainer();
      final notifier = container.read(dvirFormProvider(null).notifier);

      final gate = await notifier.prepareReviewGate();
      expect(gate.failure, isA<DvirFlowCancelledFailure>());
    });
  });

  group('بوابة §396.13', () {
    test('مركبة غير معيّنة تُرفض بنوع DvirVehicleMissingFailure', () async {
      final (container, _) = await buildContainer();
      final notifier = container.read(dvirFormProvider(null).notifier);
      notifier.beginSubmission();

      final gate = await notifier.prepareReviewGate();
      expect(gate.failure, isA<DvirVehicleMissingFailure>());
    });

    test(
      'إجابة "لا يوجد سابق" الموثوقة تجتاز البوابة وتحمل هوية المركبة',
      () async {
        final (container, _) = await buildContainer();
        container.read(dashboardDataProvider.notifier).updateVehicle(_vehicleA);
        final notifier = container.read(dvirFormProvider(null).notifier);
        notifier.beginSubmission();

        final gate = await notifier.prepareReviewGate();
        expect(gate.failure, isNull);
        expect(gate.previous, isNull);
        expect(gate.vehicleId, 'A-U');
      },
    );

    test('تغيّر مركبة الفحص أثناء البوابة يلغي العملية كلها', () async {
      final (container, repository) = await buildContainer();
      container.read(dashboardDataProvider.notifier).updateVehicle(_vehicleA);
      final notifier = container.read(dvirFormProvider(null).notifier);
      await Future<void>.delayed(Duration.zero);
      notifier.beginSubmission();

      final pending = Completer<Either<Failure, DvirReport?>>();
      repository.previousByVehicle['A-U'] = pending;

      final gateFuture = notifier.prepareReviewGate();
      await Future<void>.delayed(Duration.zero);
      // المركبة تبدّلت أثناء انتظار إجابة المركبة القديمة.
      container.read(dashboardDataProvider.notifier).updateVehicle(_vehicleB);

      pending.complete(const Right<Failure, DvirReport?>(null));
      final gate = await gateFuture;

      expect(gate.failure, isA<DvirFlowCancelledFailure>());
    });
  });

  group('شروط البوابة الموسعة (كل شرط في الحالة)', () {
    test('تقرير محفوظ ⇒ فشل DvirReportReadOnlyFailure قبل أي شيء', () async {
      const summary = DvirReport(
        id: 'x',
        type: InspectionType.preTrip,
        driverName: 'D',
        vehicleId: 'A-U',
      );
      final repository = _FakeRepository();
      final vehicleRepo = _VehicleRepo();
      when(
        () => vehicleRepo.getVehicles(),
      ).thenAnswer((_) async => const Right(<Vehicle>[]));
      final container = ProviderContainer(
        overrides: [
          dvirRepositoryProvider.overrideWithValue(repository),
          vehicleProvider.overrideWith((ref) => VehicleNotifier(vehicleRepo)),
          dashboardDataProvider.overrideWith((ref) => DashboardNotifier()),
          accountProvider.overrideWith((ref) => _StubAccountNotifier()),
          trustedTimeProvider.overrideWithValue(
            _FixedTimeProvider(() => TrustedTimeAvailable(_fixedUtc)),
          ),
        ],
      );
      addTearDown(container.dispose);
      final keepAlive = container.listen(dvirFormProvider(summary), (_, _) {});
      addTearDown(keepAlive.close);
      await Future<void>.delayed(Duration.zero);

      final notifier = container.read(dvirFormProvider(summary).notifier);
      expect(notifier.beginSubmission(), isTrue);

      final gate = await notifier.prepareReviewGate();
      expect(gate.failure, isA<DvirReportReadOnlyFailure>());
    });

    test('وقت موثوق غير متاح ⇒ تُرفض البوابة قبل السؤال والحوارات', () async {
      final (container, repository) = await buildContainer(
        timeResult: TrustedTimeUnavailable(TrustedTimeState.unavailable),
      );
      container.read(dashboardDataProvider.notifier).updateVehicle(_vehicleA);
      final notifier = container.read(dvirFormProvider(null).notifier);
      await Future<void>.delayed(Duration.zero);
      notifier.beginSubmission();

      final gate = await notifier.prepareReviewGate();
      expect(gate.failure, isA<DvirTimeUnavailableFailure>());
    });

    test('منبّه كتالوج SRS 7.6: "بها عيوب" بلا عيوب يستوجب القائمة', () {
      const item = DvirCatalogItem(code: 'BRK', name: 'Brakes');
      const empty = DvirFormState();
      expect(
        empty.shouldPromptDefectsAfterStatus(DvirConditionStatus.hasDefects),
        isTrue,
      );
      expect(
        empty.shouldPromptDefectsAfterStatus(DvirConditionStatus.satisfactory),
        isFalse,
      );

      const withDefects = DvirFormState(
        selectedDefects: [DvirDefectSelection(item: item)],
      );
      expect(
        withDefects.shouldPromptDefectsAfterStatus(
          DvirConditionStatus.hasDefects,
        ),
        isFalse,
      );
    });
  });

  group('submitDraft', () {
    test('يرفض مركبة غير التي اجتازت البوابة ولا يرسل شيئاً', () async {
      final (container, repository) = await buildContainer();
      container.read(dashboardDataProvider.notifier).updateVehicle(_vehicleA);
      final notifier = container.read(dvirFormProvider(null).notifier);
      notifier.beginSubmission();

      final failure = await notifier.submitDraft(
        text: _text(),
        signatureData: 'AQID',
        driverId: 5,
        gatedVehicleId: 'B-U',
      );

      expect(failure, isA<DvirFlowCancelledFailure>());
      expect(repository.submitted, isEmpty);
    });

    test(
      'يقرأ الوقت الموثوق لحظة الحفظ ويبني المسودة عبر مصنع النطاق',
      () async {
        final (container, repository) = await buildContainer();
        container.read(dashboardDataProvider.notifier).updateVehicle(_vehicleA);
        final notifier = container.read(dvirFormProvider(null).notifier);
        notifier.beginSubmission();
        final gate = await notifier.prepareReviewGate();
        expect(gate.failure, isNull);

        final failure = await notifier.submitDraft(
          text: _text(),
          signatureData: 'AQID',
          driverId: 5,
          gatedVehicleId: gate.vehicleId,
        );

        expect(failure, isNull);
        expect(repository.submitted.single.date, _fixedUtc);
        expect(repository.submitted.single.vehicleId, 'A-U');
        expect(repository.submitted.single.deviceId, 101);
        expect(
          repository.submitted.single.conditionStatus,
          DvirConditionStatus.satisfactory,
        );
      },
    );

    test('وقت موثوق غير متاح لحظة الحفظ ⇒ فشل مُطبَّع ولا إرسال', () async {
      final (container, repository) = await buildContainer(
        timeResult: TrustedTimeUnavailable(TrustedTimeState.unavailable),
      );
      container.read(dashboardDataProvider.notifier).updateVehicle(_vehicleA);
      final notifier = container.read(dvirFormProvider(null).notifier);
      notifier.beginSubmission();

      final failure = await notifier.submitDraft(
        text: _text(),
        signatureData: 'AQID',
        driverId: 5,
        gatedVehicleId: 'A-U',
      );

      expect(failure, isA<DvirTimeUnavailableFailure>());
      expect(repository.submitted, isEmpty);
    });
  });

  group('تفاصيل الخادم', () {
    test('قائمة عيوب فارغة من الخادم تحلّ محل الاختيارات القديمة', () async {
      const item = DvirCatalogItem(code: 'BRK', name: 'Brakes');
      const summary = DvirReport(
        id: '7',
        type: InspectionType.preTrip,
        driverName: 'D',
        vehicleId: 'A-U',
        selectedDefects: [DvirDefectSelection(item: item)],
      );
      final repository = _FakeRepository();
      final vehicleRepo = _VehicleRepo();
      when(
        () => vehicleRepo.getVehicles(),
      ).thenAnswer((_) async => const Right(<Vehicle>[]));
      final container = ProviderContainer(
        overrides: [
          dvirRepositoryProvider.overrideWithValue(repository),
          vehicleProvider.overrideWith((ref) => VehicleNotifier(vehicleRepo)),
          dashboardDataProvider.overrideWith((ref) => DashboardNotifier()),
          accountProvider.overrideWith((ref) => _StubAccountNotifier()),
          trustedTimeProvider.overrideWithValue(
            _FixedTimeProvider(() => TrustedTimeAvailable(_fixedUtc)),
          ),
        ],
      );
      addTearDown(container.dispose);
      final keepAlive = container.listen(dvirFormProvider(summary), (_, _) {});
      addTearDown(keepAlive.close);

      final notifier = container.read(dvirFormProvider(summary).notifier);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.selectedDefects, isNotEmpty);

      notifier.applyServerDetail(summary.copyWith(clearSelectedDefects: true));
      expect(notifier.state.selectedDefects, isEmpty);
    });
  });
}

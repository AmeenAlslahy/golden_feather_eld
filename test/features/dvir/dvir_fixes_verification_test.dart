import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/contracts/dvir_backend.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/services/tracking_config_storage_service.dart';
import 'package:golden_feather_eld/features/dvir/data/mappers/dvir_mappers.dart';
import 'package:golden_feather_eld/features/dvir/data/repositories/dvir_repository_impl.dart';
import 'package:golden_feather_eld/features/dvir/domain/dvir_catalog.dart';
import 'package:golden_feather_eld/features/dvir/domain/dvir_vehicle.dart';
import 'package:golden_feather_eld/features/dvir/domain/entities/dvir_report.dart';
import 'package:golden_feather_eld/features/dvir/presentation/providers/dvir_provider.dart';
import 'package:golden_feather_eld/features/sync/data/repositories/memory_offline_queue.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:mocktail/mocktail.dart';

class _MockDvirBackend extends Mock implements DvirBackend {}
class _MockStorageService extends Mock implements TrackingConfigStorageService {}

class _OnlineNetworkInfo implements NetworkInfo {
  @override
  bool get isConnected => true;
  @override
  Stream<bool> get onConnectionChange => const Stream.empty();
}

void main() {
  setUpAll(() {
    registerFallbackValue(const DvirId(1));
    registerFallbackValue(<String, dynamic>{});
  });
  group('DVIR-01: DvirConditionStatus.fromWire unknown handling', () {
    test('unrecognized string returns unknown (never silently satisfactory)', () {
      expect(DvirConditionStatus.fromWire('Random Unknown String'), DvirConditionStatus.unknown);
      expect(DvirConditionStatus.fromWire('Out of Service'), DvirConditionStatus.unknown);
      expect(DvirConditionStatus.fromWire(null), DvirConditionStatus.unknown);
      expect(DvirConditionStatus.fromWire(''), DvirConditionStatus.unknown);
      expect(DvirConditionStatus.fromWire('   '), DvirConditionStatus.unknown);
    });

    test('recognized wire strings return exact enum', () {
      expect(DvirConditionStatus.fromWire('Vehicle Condition Satisfactory'), DvirConditionStatus.satisfactory);
      expect(DvirConditionStatus.fromWire('Has Defects'), DvirConditionStatus.hasDefects);
      expect(DvirConditionStatus.fromWire('Defects Corrected'), DvirConditionStatus.defectsCorrected);
      expect(DvirConditionStatus.fromWire('Defects Need Not Be Corrected'), DvirConditionStatus.defectsNotCorrected);
    });
  });

  group('DVIR-02 & DVIR-10: Date parsing & retention calculation', () {
    late _MockDvirBackend backend;
    late DvirRepositoryImpl repository;

    setUp(() {
      backend = _MockDvirBackend();
      repository = DvirRepositoryImpl(
        dvirBackend: backend,
        networkInfo: _OnlineNetworkInfo(),
        offlineQueue: MemoryOfflineQueue(),
      );
    });

    test('malformed or missing dates do not invent DateTime.now()', () async {
      when(() => backend.getById(any())).thenAnswer(
        (_) async => ok(<String, dynamic>{
          'id': 100,
          'inspectionTime': 'not-a-valid-date',
          'createdAt': null,
          'status': 'Vehicle Condition Satisfactory',
        }),
      );

      final result = await repository.getDvirDetails('100');
      expect(result.isRight(), isTrue);
      final report = result.getOrElse((_) => throw StateError('left'));
      expect(report.date, isNull);
      expect(report.retentionUntil, isNull);
    });

    test('valid date parses correctly and computes clamped retentionUntil', () {
      // Nov 30 -> 3 months later is Feb (28 or 29), not March!
      final report = DvirReport(
        id: '1',
        type: InspectionType.preTrip,
        date: DateTime.utc(2024, 11, 30, 10, 0),
        driverName: 'Driver',
        vehicleId: 'V1',
      );

      final retention = report.retentionUntil;
      expect(retention, isNotNull);
      expect(retention!.year, 2025);
      expect(retention.month, 2);
      expect(retention.day, 28); // 2025 is not leap year
    });

    test('leap year retention clamp handles Feb 29 correctly', () {
      // Nov 30, 2023 -> Feb 29, 2024 (leap year)
      final report = DvirReport(
        id: '2',
        type: InspectionType.preTrip,
        date: DateTime.utc(2023, 11, 30, 10, 0),
        driverName: 'Driver',
        vehicleId: 'V1',
      );

      final retention = report.retentionUntil;
      expect(retention, isNotNull);
      expect(retention!.year, 2024);
      expect(retention.month, 2);
      expect(retention.day, 29);
    });
  });

  group('DVIR-03: getPreviousDvir repository contract', () {
    late _MockDvirBackend backend;
    late DvirRepositoryImpl repository;

    setUp(() {
      backend = _MockDvirBackend();
      repository = DvirRepositoryImpl(
        dvirBackend: backend,
        networkInfo: _OnlineNetworkInfo(),
        offlineQueue: MemoryOfflineQueue(),
      );
    });

    test('returns Right(null) when server returns {message: "No Records"} without hasPreviousDvir', () async {
      when(() => backend.getPreviousDvir('TRUCK-1')).thenAnswer(
        (_) async => ok(<String, dynamic>{
          'success': true,
          'message': 'No Records',
        }),
      );

      final result = await repository.getPreviousDvir('TRUCK-1');
      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => throw StateError('left')), isNull);
    });

    test('returns Right(null) when server returns data: null', () async {
      when(() => backend.getPreviousDvir('TRUCK-2')).thenAnswer(
        (_) async => ok(<String, dynamic>{
          'success': true,
          'data': null,
        }),
      );

      final result = await repository.getPreviousDvir('TRUCK-2');
      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => throw StateError('left')), isNull);
    });

    test('returns Left when server says hasPreviousDvir: true but body is unreadable', () async {
      when(() => backend.getPreviousDvir('TRUCK-3')).thenAnswer(
        (_) async => ok(<String, dynamic>{
          'hasPreviousDvir': true,
          'invalidField': 123,
        }),
      );

      final result = await repository.getPreviousDvir('TRUCK-3');
      expect(result.isLeft(), isTrue);
    });
  });

  group('DVIR-04: Odometer validation', () {
    test('buildDvirCreateBody rejects negative odometer', () {
      final body = buildDvirCreateBody(
        driverId: 1,
        deviceId: 1,
        uniqueId: 'TRUCK-1',
        status: 'Has Defects',
        signatureData: 'dGVzdA==',
        inspectionTime: '2026-10-01T10:00:00Z',
        odometer: -50.0,
      );
      expect(body, isNull);
    });

    test('buildDvirCreateBody rejects NaN or infinite odometer', () {
      expect(
        buildDvirCreateBody(
          driverId: 1,
          deviceId: 1,
          uniqueId: 'TRUCK-1',
          status: 'Has Defects',
          signatureData: 'dGVzdA==',
          inspectionTime: '2026-10-01T10:00:00Z',
          odometer: double.nan,
        ),
        isNull,
      );

      expect(
        buildDvirCreateBody(
          driverId: 1,
          deviceId: 1,
          uniqueId: 'TRUCK-1',
          status: 'Has Defects',
          signatureData: 'dGVzdA==',
          inspectionTime: '2026-10-01T10:00:00Z',
          odometer: double.infinity,
        ),
        isNull,
      );
    });

    test('buildDvirCreateBody accepts valid non-negative odometer', () {
      final body = buildDvirCreateBody(
        driverId: 1,
        deviceId: 1,
        uniqueId: 'TRUCK-1',
        status: 'Has Defects',
        signatureData: 'dGVzdA==',
        inspectionTime: '2026-10-01T10:00:00Z',
        odometer: 125000.5,
      );
      expect(body, isNotNull);
      expect(body!['odometer'], 125000.5);
    });
  });

  group('DVIR-06 & DVIR-08: Provider lifecycle & stale state clearing', () {
    late _MockDvirBackend backend;
    late _MockStorageService storageService;
    late DvirRepositoryImpl repository;

    setUp(() {
      backend = _MockDvirBackend();
      storageService = _MockStorageService();
      when(() => storageService.deviceId).thenReturn('V1');
      repository = DvirRepositoryImpl(
        dvirBackend: backend,
        networkInfo: _OnlineNetworkInfo(),
        offlineQueue: MemoryOfflineQueue(),
      );
    });

    test('DvirState copyWith clearCurrentReport clears currentReport', () {
      const report = DvirReport(
        id: '42',
        type: InspectionType.preTrip,
        driverName: 'Driver',
        vehicleId: 'V1',
      );
      var state = const DvirState(currentReport: report);
      expect(state.currentReport, isNotNull);

      state = state.copyWith(clearCurrentReport: true);
      expect(state.currentReport, isNull);
    });

    test('loadDvirDetails clears stale report when fetching new one', () async {
      when(() => backend.list(uniqueId: any(named: 'uniqueId'))).thenAnswer(
        (_) async => ok(<String, dynamic>{'data': []}),
      );
      when(() => backend.getById(any())).thenAnswer(
        (_) async => ok(<String, dynamic>{
          'id': 99,
          'status': 'Vehicle Condition Satisfactory',
        }),
      );

      final notifier = DvirNotifier(
        repository: repository,
        storageService: storageService,
      );

      notifier.state = notifier.state.copyWith(
        currentReport: const DvirReport(
          id: 'old-report',
          type: InspectionType.preTrip,
          driverName: 'Old',
          vehicleId: 'V1',
        ),
      );

      await notifier.loadDvirDetails('99');
      expect(notifier.state.currentReport?.id, '99');
    });
  });

  group('DVIR-09: Reconciling report defects with status', () {
    late _MockDvirBackend backend;
    late DvirRepositoryImpl repository;

    setUp(() {
      backend = _MockDvirBackend();
      repository = DvirRepositoryImpl(
        dvirBackend: backend,
        networkInfo: _OnlineNetworkInfo(),
        offlineQueue: MemoryOfflineQueue(),
      );
    });

    test('report with defects submitted with satisfactory status is reconciled to Has Defects on wire', () async {
      when(() => backend.create(any())).thenAnswer((_) async => ok(null));

      const reportWithDefects = DvirReport(
        id: '',
        type: InspectionType.preTrip,
        driverName: 'Driver',
        vehicleId: 'V1',
        deviceId: 7,
        hasDefects: true,
        vehicleDefects: 'Brakes spongy',
        signature: 'dGVzdA==',
      );

      await repository.submitDvirReport(
        reportWithDefects,
        driverId: 10,
        status: DvirConditionStatus.satisfactory, // Contradictory input
      );

      final captured = verify(() => backend.create(captureAny())).captured.first as Map<String, dynamic>;
      expect(captured['status'], 'Has Defects');
    });
  });

  group('DVIR-11: isUnassignedVehicleId case-insensitivity', () {
    test('correctly identifies unassigned vehicle regardless of case', () {
      expect(isUnassignedVehicleId('No Vehicle'), isTrue);
      expect(isUnassignedVehicleId('no vehicle'), isTrue);
      expect(isUnassignedVehicleId('NO VEHICLE'), isTrue);
      expect(isUnassignedVehicleId('  No Vehicle  '), isTrue);
      expect(isUnassignedVehicleId(''), isTrue);
      expect(isUnassignedVehicleId(null), isTrue);
      expect(isUnassignedVehicleId('TRUCK-101'), isFalse);
    });
  });

  group('DVIR-15: DvirReport copyWith clearSelectedDefects', () {
    test('clears selected defects when clearSelectedDefects is true', () {
      const defect = DvirDefectSelection(
        item: DvirCatalogItem(code: 'C1', name: 'Brakes', category: 'BRAKES'),
      );
      const report = DvirReport(
        id: '1',
        type: InspectionType.preTrip,
        driverName: 'D',
        vehicleId: 'V',
        selectedDefects: [defect],
      );
      expect(report.selectedDefects.length, 1);

      final cleared = report.copyWith(clearSelectedDefects: true);
      expect(cleared.selectedDefects, isEmpty);
    });
  });
}

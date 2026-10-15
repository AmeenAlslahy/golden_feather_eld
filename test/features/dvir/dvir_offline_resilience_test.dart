import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/contracts/dvir_backend.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/features/dvir/data/repositories/dvir_repository_impl.dart';
import 'package:golden_feather_eld/features/dvir/domain/entities/dvir_report.dart';
import 'package:golden_feather_eld/features/sync/data/repositories/memory_offline_queue.dart';
import 'package:mocktail/mocktail.dart';

class _Backend extends Mock implements DvirBackend {}

class _Offline implements NetworkInfo {
  @override
  bool get isConnected => false;
  @override
  Stream<bool> get onConnectionChange => const Stream.empty();
}

class _Online implements NetworkInfo {
  @override
  bool get isConnected => true;
  @override
  Stream<bool> get onConnectionChange => const Stream.empty();
}

void main() {
  late _Backend backend;
  late MemoryOfflineQueue queue;

  setUp(() {
    backend = _Backend();
    queue = MemoryOfflineQueue();
  });

  DvirReport makeReport({
    String id = '101',
    String vehicleId = 'TRK-1',
    InspectionType type = InspectionType.preTrip,
    VehicleCondition condition = VehicleCondition.safe,
  }) {
    return DvirReport(
      id: id,
      deviceId: 10,
      type: type,
      date: DateTime.utc(2026, 10, 14, 8, 0),
      driverName: 'Driver One',
      vehicleId: vehicleId,
      condition: condition,
      odometer: 12500.0,
      signature: 'AQID',
      notes: 'All good',
      location: 'Dallas, TX',
      companyName: 'Golden Feather',
    );
  }

  test(
    'submitDvirReport offline enqueues event and updates cache and previous DVIR',
    () async {
      final repo = DvirRepositoryImpl(
        dvirBackend: backend,
        networkInfo: _Offline(),
        offlineQueue: queue,
      );

      final report = makeReport(id: '999', vehicleId: 'TRK-100');

      final result = await repo.submitDvirReport(
        report,
        driverId: 101,
        status: DvirConditionStatus.satisfactory,
      );

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => false), isTrue);

      // Event enqueued
      final events = await queue.getReadyEvents(limit: 10);
      expect(events.length, 1);
      expect(events.first.type, 'dvir_create');
      expect(events.first.payload['uniqueId'], 'TRK-100');

      // Cached previous DVIR is updated
      final prevResult = await repo.getPreviousDvir('TRK-100');
      expect(prevResult.isRight(), isTrue);
      final prev = prevResult.getOrElse((_) => null);
      expect(prev, isNotNull);
      expect(prev?.id, '999');

      // Cached reports list contains the submitted report
      final listResult = await repo.getDvirReports('TRK-100');
      expect(listResult.isRight(), isTrue);
      final list = listResult.getOrElse((_) => []);
      expect(list.any((r) => r.id == '999'), isTrue);
    },
  );

  test(
    'reviewDvir offline enqueues event and updates nextDriverReviewed in cache',
    () async {
      final repo = DvirRepositoryImpl(
        dvirBackend: backend,
        networkInfo: _Offline(),
        offlineQueue: queue,
      );

      final report = makeReport(id: '555', vehicleId: 'TRK-200');
      await repo.submitDvirReport(
        report,
        driverId: 101,
        status: DvirConditionStatus.satisfactory,
      );

      final reviewResult = await repo.reviewDvir(
        dvirId: '555',
        reviewingDriverId: 102,
        reviewingDriverName: 'Reviewer Driver',
        signatureData: 'SIG_DATA',
        driverAgreed: true,
        reviewNotes: 'Reviewed and agreed',
      );

      expect(reviewResult.isRight(), isTrue);
      expect(reviewResult.getOrElse((_) => false), isTrue);

      // Review event enqueued
      final events = await queue.getReadyEvents(limit: 10);
      expect(events.any((e) => e.type == 'dvir_review'), isTrue);

      // Previous report now marked as reviewed
      final prevResult = await repo.getPreviousDvir('TRK-200');
      final prev = prevResult.getOrElse((_) => null);
      expect(prev?.nextDriverReviewed, isTrue);
      expect(prev?.reviewingDriverName, 'Reviewer Driver');
    },
  );

  test(
    'submitDvirReport online with NetworkError falls back to offline queue',
    () async {
      final repo = DvirRepositoryImpl(
        dvirBackend: backend,
        networkInfo: _Online(),
        offlineQueue: queue,
      );

      when(() => backend.create(any())).thenAnswer(
        (_) async => err(
          const NetworkError(
            code: 'network.timeout',
            l10nKey: 'err_network_timeout',
          ),
        ),
      );

      final report = makeReport(id: '777', vehicleId: 'TRK-300');

      final result = await repo.submitDvirReport(
        report,
        driverId: 101,
        status: DvirConditionStatus.satisfactory,
      );

      expect(result.isRight(), isTrue);
      final events = await queue.getReadyEvents(limit: 10);
      expect(events.length, 1);
      expect(events.first.type, 'dvir_create');
      expect(events.first.payload['uniqueId'], 'TRK-300');
    },
  );
}

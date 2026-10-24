import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/contracts/dvir_backend.dart';
import 'package:golden_feather_eld/core/constants/storage_constants.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/features/dvir/data/repositories/dvir_repository_impl.dart';
import 'package:golden_feather_eld/features/dvir/domain/entities/dvir_report.dart';
import 'package:golden_feather_eld/features/sync/data/repositories/memory_offline_queue.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class _Backend extends Mock implements DvirBackend {}

class _Offline implements NetworkInfo {
  @override
  bool get isConnected => false;
  @override
  Stream<bool> get onConnectionChange => const Stream.empty();
}

Map<String, dynamic> _serverReport({int id = 42, String uniqueId = 'TRK-1'}) {
  return <String, dynamic>{
    'id': id,
    'uniqueId': uniqueId,
    'inspectionType': 'Pre-Trip',
    'inspectionTime': '2026-10-14T08:00:00Z',
    'status': 'Vehicle Condition Satisfactory',
    'driver': {'id': 5, 'name': 'Driver One'},
  };
}

Map<String, dynamic> _requestBody() {
  return <String, dynamic>{
    'driverId': 5,
    'deviceId': 10,
    'uniqueId': 'TRK-1',
    'status': 'Has Defects',
    'signatureData': 'AQID',
    'inspectionTime': '2026-10-14T08:00:00Z',
  };
}

void main() {
  late Directory directory;
  late Box<String> box;
  late DvirRepositoryImpl repository;

  setUpAll(() {
    directory = Directory.systemTemp.createTempSync('dvir_cache_integrity_');
    Hive.init(directory.path);
  });

  setUp(() async {
    box = await Hive.openBox<String>(StorageConstants.dailyLogsCacheBox);
    await box.clear();
    repository = DvirRepositoryImpl(
      dvirBackend: _Backend(),
      networkInfo: _Offline(),
      offlineQueue: MemoryOfflineQueue(),
    );
  });

  tearDownAll(() async {
    await Hive.close();
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  test(
    'a legacy request body no longer makes the whole cache unreadable',
    () async {
      box.put(
        'dvir_reports:TRK-1',
        jsonEncode([_requestBody(), _serverReport(id: 42)]),
      );

      final result = await repository.getDvirReports('TRK-1');

      expect(result.isRight(), isTrue);
      final reports = result.getOrElse((_) => const <DvirReport>[]);
      expect(reports, hasLength(1));
      expect(reports.single.id, '42');
    },
  );

  test(
    'one unreadable row is skipped instead of failing the vehicle',
    () async {
      box.put(
        'dvir_reports:TRK-2',
        jsonEncode([
          {..._serverReport(id: 50, uniqueId: 'TRK-2'), 'driver': 'broken'},
          _serverReport(id: 51, uniqueId: 'TRK-2'),
        ]),
      );

      final result = await repository.getDvirReports('TRK-2');

      expect(result.isRight(), isTrue);
      final reports = result.getOrElse((_) => const <DvirReport>[]);
      expect(reports.map((r) => r.id), ['51']);
    },
  );

  test(
    'offline submission writes no request body to the report cache',
    () async {
      const report = DvirReport(
        id: '999',
        type: InspectionType.preTrip,
        driverName: 'Driver One',
        vehicleId: 'TRK-NEW',
        deviceId: 10,
        signature: 'AQID',
      );

      final result = await repository.submitDvirReport(report, driverId: 5);

      expect(result.isRight(), isTrue);
      expect(box.get('dvir_reports:v2:TRK-NEW'), isNull);
      expect(box.get('dvir_reports:TRK-NEW'), isNull);
      expect(box.get('dvir_prev:v2:TRK-NEW'), isNull);
    },
  );

  test(
    'unknown previous answer offline is a failure, not "no previous"',
    () async {
      final result = await repository.getPreviousDvir('TRK-UNKNOWN');

      expect(result.isLeft(), isTrue);
    },
  );

  test('a known "no previous" answer survives offline restarts', () async {
    box.put(
      'dvir_prev:v2:TRK-NONE',
      jsonEncode({'version': 2, 'report': null}),
    );

    final result = await repository.getPreviousDvir('TRK-NONE');

    expect(result.isRight(), isTrue);
    expect(result.getOrElse((_) => throw StateError('left')), isNull);
  });

  test(
    'offline submit keeps the report in the session previous cache',
    () async {
      const report = DvirReport(
        id: '888',
        type: InspectionType.preTrip,
        driverName: 'Driver One',
        vehicleId: 'TRK-SESSION',
        deviceId: 10,
        signature: 'AQID',
      );

      await repository.submitDvirReport(report, driverId: 5);

      final previous = await repository.getPreviousDvir('TRK-SESSION');
      expect(previous.isRight(), isTrue);
      expect(
        previous.getOrElse((_) => null)?.id,
        '888',
        reason: 'a just-submitted report is visible for this session',
      );
    },
  );
}

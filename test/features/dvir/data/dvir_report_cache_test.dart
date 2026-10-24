import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/constants/storage_constants.dart';
import 'package:golden_feather_eld/features/dvir/data/datasources/dvir_report_cache.dart';
import 'package:hive/hive.dart';

Map<String, dynamic> _serverReport({int id = 1, String uniqueId = 'TRK-1'}) {
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
  const cache = DvirReportCache();

  setUpAll(() {
    directory = Directory.systemTemp.createTempSync('dvir_report_cache_');
    Hive.init(directory.path);
  });

  setUp(() async {
    box = await Hive.openBox<String>(StorageConstants.dailyLogsCacheBox);
    await box.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  test('request bodies are never persisted as DVIR records', () {
    cache.saveReports('TRK-1', [
      _serverReport(),
      _requestBody(),
      {'id': null},
      {'id': 'not-a-number'},
    ]);

    final stored = jsonDecode(box.get('dvir_reports:v2:TRK-1')!) as Map;
    final reports = stored['reports'] as List;
    expect(reports, hasLength(1));
    expect(reports.single['id'], 1);

    final read = cache.readReports('TRK-1');
    expect(read, hasLength(1));
    expect(read!.single['id'], 1);
  });

  test('legacy cache is migrated: valid rows survive, poisoned rows drop', () {
    box.put(
      'dvir_reports:TRK-2',
      jsonEncode([_requestBody(), _serverReport(id: 2, uniqueId: 'TRK-2')]),
    );

    final read = cache.readReports('TRK-2');
    expect(read, hasLength(1));
    expect(read!.single['id'], 2);
    expect(box.get('dvir_reports:TRK-2'), isNull);
    expect(box.get('dvir_reports:v2:TRK-2'), isNotNull);
  });

  test('a legacy cache with no valid row becomes a known empty answer', () {
    box.put('dvir_reports:TRK-3', jsonEncode([_requestBody()]));

    expect(cache.readReports('TRK-3'), isEmpty);
    expect(box.get('dvir_reports:TRK-3'), isNull);
  });

  test('unreadable JSON does not break the cache', () {
    box.put('dvir_reports:v2:TRK-4', '{not-json');
    expect(cache.readReports('TRK-4'), isNull);
  });

  test('a known empty list round-trips distinctly from "no cache"', () {
    expect(cache.readReports('TRK-5'), isNull);
    cache.saveReports('TRK-5', const []);
    expect(cache.readReports('TRK-5'), isEmpty);
  });

  test('previous DVIR cache is tri-state', () {
    expect(cache.readPrevious('TRK-6'), isNull);

    cache.saveNoPrevious('TRK-6');
    final none = cache.readPrevious('TRK-6');
    expect(none, isNotNull);
    expect(none!.report, isNull);

    cache.savePrevious('TRK-6', _serverReport(id: 6));
    final found = cache.readPrevious('TRK-6');
    expect(found!.report?['id'], 6);
  });

  test('a poisoned legacy previous row is unknown, not a crash', () {
    box.put('dvir_prev:TRK-7', jsonEncode(_requestBody()));
    expect(cache.readPrevious('TRK-7'), isNull);
  });

  test('markReviewCompleted updates the list and the previous answer', () {
    cache.saveReports('TRK-8', [_serverReport(id: 8, uniqueId: 'TRK-8')]);
    cache.savePrevious('TRK-8', _serverReport(id: 8, uniqueId: 'TRK-8'));

    cache.markReviewCompleted(
      vehicleId: 'TRK-8',
      dvirId: 8,
      reviewerName: 'Next Driver',
    );

    final reports = cache.readReports('TRK-8')!;
    expect(reports.single['nextDriverReviewed'], isTrue);
    expect(reports.single['reviewingDriverName'], 'Next Driver');

    final previous = cache.readPrevious('TRK-8')!;
    expect(previous.report?['nextDriverReviewed'], isTrue);
    expect(previous.report?['reviewingDriverName'], 'Next Driver');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/dvir/data/mappers/dvir_defect_mappers.dart';

void main() {
  // شكل حي من GET /eld/dvir/defects/{id} (مواصفة §07.1) — لا حقول مخترعة.
  final liveDefect = {
    'id': 42,
    'inspectionId': 130,
    'deviceId': 485,
    'driverId': 101,
    'assetType': 'VEHICLE',
    'assetIdentifier': 'Truck #1001',
    'itemCode': 'BRAKES',
    'itemName': 'Brakes',
    'description': 'Air leak detected in rear brake chamber',
    'severity': 'HIGH',
    'stage': 'OPEN',
    'outOfService': true,
    'repairDeadline': '2026-10-05T17:23:03.374Z',
    'repairActions': [
      {
        'id': 10,
        'performedByName': 'Mechanic John',
        'actionPerformed': 'REPAIRED',
        'repairNotes': 'Replaced faulty valve',
        'workOrderNumber': 'WO-98421',
        'performedAt': '2026-10-05T17:23:03.374Z',
      },
    ],
    'certifications': [
      {
        'id': 5,
        'certifiedByName': 'Carrier Safety Officer',
        'certificationType': 'REPAIRED',
        'certificationNotes': 'Certified safe for operation',
        'certifiedAt': '2026-10-05T17:23:03.374Z',
      },
    ],
  };

  group('parseDvirDefect', () {
    test('parses the live defect payload including lifecycle lists', () {
      final defect = parseDvirDefect(liveDefect);
      expect(defect, isNotNull);
      expect(defect!.id, 42);
      expect(defect.itemCode, 'BRAKES');
      expect(defect.severity, 'HIGH');
      expect(defect.stage, 'OPEN');
      expect(defect.outOfService, isTrue);
      expect(defect.repairActions, hasLength(1));
      expect(defect.repairActions.first.performedByName, 'Mechanic John');
      expect(defect.repairActions.first.workOrderNumber, 'WO-98421');
      expect(defect.certifications, hasLength(1));
      expect(defect.certifications.first.certifiedByName,
          'Carrier Safety Officer');
    });

    test('absent fields stay null and unknown id returns null', () {
      final defect = parseDvirDefect({'itemName': 'Brakes'});
      expect(defect, isNull); // لا معرف = جسم غير موثوق
      expect(parseDvirDefect(null), isNull);
      expect(parseDvirDefect('not-a-map'), isNull);
    });

    test('non-integer ids are tolerated when parseable', () {
      final defect = parseDvirDefect({'id': '42', 'stage': 'OPEN'});
      expect(defect!.id, 42);
      expect(defect.repairActions, isEmpty);
      expect(defect.certifications, isEmpty);
    });
  });

  group('parseDvirDefectList', () {
    test('accepts a bare list and enveloped shapes', () {
      final bare = parseDvirDefectList([liveDefect]);
      expect(bare, hasLength(1));
      expect(bare!.first.id, 42);

      final enveloped = parseDvirDefectList({'data': [liveDefect]});
      expect(enveloped, hasLength(1));

      final items = parseDvirDefectList({'items': [liveDefect]});
      expect(items, hasLength(1));
    });

    test('one unreadable row rejects the whole body (never partial truth)', () {
      expect(
        parseDvirDefectList([liveDefect, {'itemName': 'no-id-row'}]),
        isNull,
      );
      expect(parseDvirDefectList({'unexpected': true}), isNull);
    });
  });
}

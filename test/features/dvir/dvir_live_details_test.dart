import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/models/dvir_dto.dart';
import 'package:golden_feather_eld/features/dvir/data/mappers/dvir_mappers.dart';
import 'package:golden_feather_eld/features/dvir/domain/dvir_catalog.dart';
import 'package:golden_feather_eld/features/dvir/domain/entities/dvir_report.dart';

void main() {
  group('Live GET /eld/dvir/303 contract & parsing verification', () {
    const liveServerJson = {
      'id': 303,
      'inspectionKind': 'DVIR',
      'inspectionType': 'PRE_TRIP',
      'inspectionTime': '2026-11-07T23:52:56.562798Z',
      'status': 'DEFECTS_EXIST_SAFE',
      'vehicleCondition': 'DEFECTS_EXIST_SAFE',
      'operatingStatus': 'AVAILABLE',
      'result': 'CONDITIONAL',
      'odometer': 58767,
      'notes': 'فحص',
      'driver': {'id': 101, 'name': 'إبراهيم الشامي'},
      'vehicle': {
        'id': 503,
        'name': 'Peterbilt 579 #103 (Standby/??? ???)',
        'uniqueId': '503',
      },
      'location': {
        'locationText': '15.3782154, 44.167181',
        'latitude': 15.3782154,
        'longitude': 44.167181,
      },
      'trailers': [
        {
          'trailerNumber': '5554',
          'detects': ['TR_KING_PIN', 'TR_COUPLING', 'TR_BRAKES'],
        },
      ],
      'detects': [
        {
          'id': 281,
          'assetType': 'VEHICLE',
          'assetIdentifier': '503',
          'itemCode': 'BRAKES_PARKING',
          'itemName': 'BRAKES_PARKING',
          'description': 'BRAKES_PARKING',
          'severity': 'LOW',
          'stage': 'OPEN',
          'outOfService': false,
          'createdAt': '2026-11-07T23:52:57.487143Z',
        },
        {
          'id': 282,
          'assetType': 'VEHICLE',
          'assetIdentifier': '503',
          'itemCode': 'BRAKES_SERVICE',
          'itemName': 'BRAKES_SERVICE',
          'description': 'BRAKES_SERVICE',
          'severity': 'LOW',
          'stage': 'OPEN',
          'outOfService': false,
          'createdAt': '2026-11-07T23:52:57.487158Z',
        },
        {
          'id': 283,
          'assetType': 'VEHICLE',
          'assetIdentifier': '503',
          'itemCode': 'STEERING_MECHANISM',
          'itemName': 'STEERING_MECHANISM',
          'description': 'STEERING_MECHANISM',
          'severity': 'LOW',
          'stage': 'OPEN',
          'outOfService': false,
          'createdAt': '2026-11-07T23:52:57.487162Z',
        },
        {
          'id': 284,
          'assetType': 'TRAILER',
          'assetIdentifier': '5554',
          'itemCode': 'TR_KING_PIN',
          'itemName': 'TR_KING_PIN',
          'description': 'TR_KING_PIN',
          'severity': 'LOW',
          'stage': 'OPEN',
          'outOfService': false,
          'createdAt': '2026-11-07T23:52:57.487166Z',
        },
        {
          'id': 285,
          'assetType': 'TRAILER',
          'assetIdentifier': '5554',
          'itemCode': 'TR_COUPLING',
          'itemName': 'TR_COUPLING',
          'description': 'TR_COUPLING',
          'severity': 'LOW',
          'stage': 'OPEN',
          'outOfService': false,
          'createdAt': '2026-11-07T23:52:57.487197Z',
        },
        {
          'id': 286,
          'assetType': 'TRAILER',
          'assetIdentifier': '5554',
          'itemCode': 'TR_BRAKES',
          'itemName': 'TR_BRAKES',
          'description': 'TR_BRAKES',
          'severity': 'LOW',
          'stage': 'OPEN',
          'outOfService': false,
          'createdAt': '2026-11-07T23:52:57.487201Z',
        },
      ],
      'photos': [],
      'signature': {
        'signed': true,
        'signedAt': '2026-11-07T23:52:56.562798Z',
        'signatureData': 'iVBORw0KGgoAAAANSUhEUgAAAlgAA',
      },
      'previousReview': null,
      'certified': true,
      'locked': true,
      'syncStatus': 'SYNCED',
      'clientUuid': '1b8ac7de-2479-484e-855f-0435b19d748a',
      'retentionUntil': '2027-02-07',
      'createdAt': '2026-11-07T23:52:57.487064Z',
      'updatedAt': '2026-11-07T23:52:57.487208Z',
    };

    test('parses all 6 defects from root detects without dropping vehicle defects', () {
      final dto = DvirDto.fromJson(liveServerJson);

      expect(dto.id, 303);
      expect(dto.defects.length, 6);
      expect(dto.defectsCount, 6);
      expect(dto.hasDefects, isTrue);

      final codes = dto.defects.map((d) => d.itemCode).toList();
      expect(codes, containsAll([
        'BRAKES_PARKING',
        'BRAKES_SERVICE',
        'STEERING_MECHANISM',
        'TR_KING_PIN',
        'TR_COUPLING',
        'TR_BRAKES',
      ]));

      // Rich properties preserved
      final parkingBrake = dto.defects.firstWhere((d) => d.itemCode == 'BRAKES_PARKING');
      expect(parkingBrake.id, 281);
      expect(parkingBrake.category, 'VEHICLE');
      expect(parkingBrake.severity, 'LOW');
      expect(parkingBrake.stage, 'OPEN');

      final kingPin = dto.defects.firstWhere((d) => d.itemCode == 'TR_KING_PIN');
      expect(kingPin.id, 284);
      expect(kingPin.category, 'TRAILER');
    });

    test('signature object extracts signatureData correctly', () {
      final dto = DvirDto.fromJson(liveServerJson);
      expect(dto.signatureData, 'iVBORw0KGgoAAAANSUhEUgAAAlgAA');
    });

    test('vehicle name, odometer, retention, and location are parsed', () {
      final dto = DvirDto.fromJson(liveServerJson);
      expect(dto.uniqueId, '503');
      expect(dto.vehicleName, 'Peterbilt 579 #103 (Standby/??? ???)');
      expect(dto.odometer, 58767.0);
      expect(dto.location, '15.3782154, 44.167181');
      expect(dto.latitude, 15.3782154);
      expect(dto.longitude, 44.167181);
      expect(dto.retentionUntil, '2027-02-07');
    });

    test('maps cleanly to DvirReport entity', () {
      final dto = DvirDto.fromJson(liveServerJson);
      final report = mapDvirDtoToReport(dto);

      expect(report.id, '303');
      expect(report.vehicleId, '503');
      expect(report.vehicleName, 'Peterbilt 579 #103 (Standby/??? ???)');
      expect(report.conditionStatus, DvirConditionStatus.hasDefects);
      expect(report.condition, VehicleCondition.needsRepair);
      expect(report.signature, 'iVBORw0KGgoAAAANSUhEUgAAAlgAA');
      expect(report.selectedDefects.length, 6);
      expect(report.retentionUntil, DateTime.parse('2027-02-07'));

      // Trailer vs Vehicle defect classification
      final vehicleDefects = report.selectedDefects.where((d) => !d.item.isTrailer).toList();
      final trailerDefects = report.selectedDefects.where((d) => d.item.isTrailer).toList();
      expect(vehicleDefects.length, 3);
      expect(trailerDefects.length, 3);

      // Humanized names & standard names
      final kingPin = trailerDefects.firstWhere((d) => d.item.code == 'TR_KING_PIN');
      expect(kingPin.item.name, 'Coupling (King) Pin');
      expect(kingPin.item.nameAr, 'مسمار التثبيت (King Pin)');

      final pb = vehicleDefects.firstWhere((d) => d.item.code == 'BRAKES_PARKING');
      expect(pb.item.name, 'Brakes Parking');
    });
  });
}

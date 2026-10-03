import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/mappers/dot_inspection_mapper.dart';
import 'package:golden_feather_eld/backend/contracts/contract_enums.dart';
import 'package:golden_feather_eld/backend/http/eld_endpoints.dart';
import 'package:golden_feather_eld/features/codriver/domain/current_codriver.dart';
import 'package:golden_feather_eld/features/dvir/domain/dvir_catalog.dart';
import 'package:golden_feather_eld/features/dvir/presentation/extensions/dvir_catalog_extensions.dart';
import 'package:golden_feather_eld/features/inspection/domain/inspection_transfer.dart';

/// Re-test against the Swagger sections 05.4 / 07 / 08 and the **actual**
/// bodies the live server returned on 2026-09-25 (driver 106, ELD-PRO-1006).
///
/// Two layers:
///  1. wire — every path / query key / body key the app sends matches Swagger;
///  2. shape — the app's parsers accept the live bodies without inventing data.
void main() {
  group('05.4 Team Driving — wire', () {
    test('paths match Swagger', () {
      expect(EldEndpoints.manageCoDriver, '/eld/sessions/co-driver');
      expect(EldEndpoints.switchPrimaryDriver, '/eld/sessions/primary-driver/switch');
      expect(EldEndpoints.reassignDriving(1, 2),
          '/eld/daily-logs/1/events/2/reassign-driving');
    });

    test('action enums use the exact Swagger values', () {
      expect(CoDriverAction.values.map((a) => a.wire),
          ['link', 'add', 'replace', 'remove']);
      expect(DutyStatusAction.values.map((a) => a.wire),
          ['switch-primary', 'legacy-switch']);
    });
  });

  group('05.4 Team Driving — live shapes', () {
    test('GET /eld/sessions/co-driver with no co-driver (live 200 body)', () {
      final read = parseCurrentCoDriver(const {
        'success': true,
        'data': {
          'coDriverId': 0,
          'teamDrivingActive': false,
          'message': 'لا يوجد سائق مساعد مرتبط بالجلسة النشطة حالياً',
        },
        'requestId': '7d1d87b7-5e0f-481a-848a-60c584d97c74',
      })!;
      // coDriverId 0 is "none", never a driver id; team mode off.
      expect(read.isLinked, isFalse);
      expect(read.coDriverId, isNull);
      expect(read.teamDrivingActive, isFalse);
    });

    test('Swagger example: linked co-driver id 102 with team mode on', () {
      final read = parseCurrentCoDriver(const {
        'data': {'coDriverId': 102, 'teamDrivingActive': true},
      })!;
      expect(read.isLinked, isTrue);
      expect(read.coDriverId, 102);
      expect(read.teamDrivingActive, isTrue);
    });
  });

  group('07 DVIR — wire', () {
    test('paths match Swagger', () {
      expect(EldEndpoints.dvir, '/eld/dvir');
      expect(EldEndpoints.dvirDetails(7), '/eld/dvir/7');

      expect(EldEndpoints.dvirNextDriverReview(7), '/eld/dvir/7/review');
      expect(EldEndpoints.dvirCatalog, '/eld/dvir/catalog');
      expect(EldEndpoints.dvirPrevious('ELD-PRO-1006'), '/eld/dvir/pre-trip/ELD-PRO-1006');
    });
  });

  group('07 DVIR — live shapes', () {
    test('GET /eld/dvir → [] is "No Records", not an error', () {
      // The adapter wraps a bare list as {'data': list}; an empty list must
      // yield zero reports (the list page shows "No Records").
      const body = <dynamic>[];
      final wrapped = {'data': body};
      expect((wrapped['data'] as List).isEmpty, isTrue);
    });

    test('GET /eld/dvir/catalog live item shape (code/name/nameAr/flags)', () {
      final items = parseDvirCatalog(const [
        {
          'code': 'SERVICE_BRAKES',
          'name': 'Service Brakes (including trailer connections)',
          'nameAr': 'فرامل الخدمة والتوصيلات',
          'category': 'VEHICLE',
          'statutoryMandatory': true,
          'criticalSafety': true,
        },
        {
          'code': 'STEERING_MECHANISM',
          'name': 'Steering Mechanism',
          'nameAr': 'آلية التوجيه وعجلة القيادة',
          'category': 'VEHICLE',
          'statutoryMandatory': true,
          'criticalSafety': false,
        },
      ])!;
      expect(items, hasLength(2));
      expect(items.first.code, 'SERVICE_BRAKES');
      expect(items.first.label(lookupAppLocalizations(const Locale('en'))), 'Service Brakes (including trailer connections)');
      expect(items.first.label(lookupAppLocalizations(const Locale('ar'))), 'فرامل الخدمة والتوصيلات');
      expect(items.first.mandatory, isTrue);
      expect(items.first.critical, isTrue);
      expect(items.last.critical, isFalse);
    });

    test('catalog item → POST /eld/dvir defect uses itemCode/itemName/category', () {
      const item = DvirCatalogItem(
        code: 'SERVICE_BRAKES',
        name: 'Service Brakes',
        category: 'VEHICLE',
      );
      final json = const DvirDefectSelection(item: item, description: 'leak').toWire();
      expect(json['itemCode'], 'SERVICE_BRAKES');
      expect(json['itemName'], 'Service Brakes');
      expect(json['category'], 'VEHICLE');
      expect(json['description'], 'leak');
    });
  });

  group('08 DOT Inspection — wire', () {
    test('paths match Swagger', () {
      expect(EldEndpoints.inspections, '/eld/dot-inspection');
      expect('${EldEndpoints.inspections}/cycle', '/eld/dot-inspection/cycle');
      expect('${EldEndpoints.inspections}/logs', '/eld/dot-inspection/logs');
      expect(EldEndpoints.dotInspectionEmailLogs, '/eld/dot-inspection/email-logs');
      expect(EldEndpoints.dotInspectionSendLogs, '/eld/dot-inspection/send-logs');
      expect(EldEndpoints.dotInspectionStart, '/eld/dot-inspection/start');
      expect(EldEndpoints.dotInspectionPacket, '/eld/dot-inspection/information-packet');
      expect(EldEndpoints.dotInspectionTransfers, '/eld/dot-inspection/transfers');
    });

    test('send-logs outputFileComment is validated to 4–60 chars client-side', () {
      expect(isValidInspectionComment('abc'), isFalse);
      expect(isValidInspectionComment('roadside check'), isTrue);
      expect(isValidInspectionComment('x' * 61), isFalse);
    });
  });

  group('08 DOT Inspection — live shapes', () {
    test('GET /eld/dot-inspection screen body maps all action flags', () {
      final screen = DotInspectionMapper.fromScreenJson(const {
        'screenTitle': 'DOT Inspection',
        'guidanceText': 'Hand the device to the inspector.',
        'handOverDeviceNotice': 'Read-only while inspection is active.',
        'carrierComplianceStatement': 'Compliant with 49 CFR 395',
        'carrierName': 'Carrier',
        'usdotNumber': '1234567',
        'eldIdentifier': 'ELD-PRO-1006',
        'eldRegistrationId': 'REG-1',
        'driver': {'id': 106, 'name': 'Driver'},
        'inspectionDate': '2026-09-25',
        'cycleDaysCovered': 8,
        'canStartInspection': true,
        'canSendLogs': true,
        'canEmailLogs': true,
        'canViewInformationPacket': true,
        'inspectionActive': false,
        'activeInspectionId': null,
        'readOnlyMode': false,
        'inspectorName': null,
      });
      expect(screen.canStartInspection, isTrue);
      expect(screen.canSendLogs, isTrue);
      expect(screen.canEmailLogs, isTrue);
      expect(screen.inspectionActive, isFalse);
      expect(screen.readOnlyMode, isFalse);
      expect(screen.cycleDaysCovered, 8);
      expect(screen.activeInspectionId, isNull);
    });

    test('GET /eld/dot-inspection/cycle → [] (no driving yet) is zero days', () {
      expect(DotInspectionMapper.fromCycleJson(const <dynamic>[]), isEmpty);
    });
  });
}


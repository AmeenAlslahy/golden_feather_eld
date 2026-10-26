import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/logs/data/models/daily_log_dto.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';

void main() {
  group('DailyLogDto BUG A Regression Tests', () {
    test('valid logDate is parsed correctly', () {
      final json = {
        'id': 1,
        'uniqueId': 'T-1',
        'logDate': '2026-10-01T00:00:00Z',
        'totalDurationMinutes': 120,
      };

      final dto = DailyLogDto.fromJson(json);
      expect(dto.logDate, '2026-10-01T00:00:00Z');

      final entity = dto.toEntity();
      expect(entity.date.year, 2026);
      expect(entity.date.month, 10);
      expect(entity.date.day, 1);
    });

    test('detail body fields are parsed from the live server payload', () {
      // شكل حي 2026-10-04 من GET /eld/daily-logs/17 — لا حقول مخترعة:
      // ما لا يرسله الخادم يبقى null في الكيان.
      final json = {
        'id': 17,
        'driver': {'id': 106, 'name': 'عبدالعزيز بن ناصر الغامدي'},
        'uniqueId': 'ELD-PRO-1006',
        'vehicleName': 'شاحنة مرسيدس أكتروس - Truck #1006',
        'vin': '1FUJGLDR5PL100606',
        'licensePlate': '1006-KSA',
        'carrierName': 'الشركة الناقلة الرسمية',
        'usdotNumber': 'غير مسجل',
        'mainOfficeAddress': 'المقر الرئيسي للشركة',
        'homeTerminalAddress': 'المحطة الرئيسية',
        'logDate': '2026-10-01',
        'logStatus': 'OPEN',
        'formStatus': 'DRAFT',
        'certificationStatus': 'NOT_READY',
        'teamMode': false,
        'requiresAction': true,
        'totalDurationMinutes': 0,
        'trailers': <String>[],
        'shippingDocuments': <String>[],
      };

      final entity = DailyLogDto.fromJson(json).toEntity();
      expect(entity.driverName, 'عبدالعزيز بن ناصر الغامدي');
      expect(entity.vehicleName, 'شاحنة مرسيدس أكتروس - Truck #1006');
      expect(entity.vin, '1FUJGLDR5PL100606');
      expect(entity.licensePlate, '1006-KSA');
      expect(entity.carrierName, 'الشركة الناقلة الرسمية');
      expect(entity.usdotNumber, 'غير مسجل');
      expect(entity.mainOfficeAddress, 'المقر الرئيسي للشركة');
      expect(entity.homeTerminalAddress, 'المحطة الرئيسية');
      expect(entity.trailers, isEmpty);
      expect(entity.shippingDocuments, isEmpty);
      expect(entity.requiresAction, isTrue);
    });

    test('list-row payload without detail fields keeps them null', () {
      final entity = DailyLogDto.fromJson({
        'id': 2,
        'uniqueId': 'T-2',
        'logDate': '2026-10-04',
        'totalDurationMinutes': 60,
      }).toEntity();
      expect(entity.driverName, isNull);
      expect(entity.carrierName, isNull);
      expect(entity.trailers, isEmpty);
    });

    test(
      'missing logDate throws FormatException, does not silently become now',
      () {
        final json = {
          'id': 1,
          'uniqueId': 'T-1',
          // 'logDate' is missing
        };

        expect(
          () => DailyLogDto.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test(
      'invalid logDate throws FormatException, does not silently become now',
      () {
        final json = {'id': 1, 'uniqueId': 'T-1', 'logDate': 'INVALID_DATE'};

        final dto = DailyLogDto.fromJson(json);
        expect(() => dto.toEntity(), throwsA(isA<FormatException>()));
      },
    );

    test(
      'COMPLETE and DRAFT formStatus are parsed correctly into entities',
      () {
        final completeEntity = DailyLogDto.fromJson({
          'id': 10,
          'logDate': '2026-10-14',
          'formStatus': 'COMPLETE',
          'certificationStatus': 'CERTIFIED',
        }).toEntity();
        expect(completeEntity.formStatus, FormStatus.completed);
        expect(completeEntity.isFormComplete, isTrue);
        expect(
          completeEntity.certificationStatus,
          CertificationStatus.certified,
        );
        expect(completeEntity.isCertified, isTrue);

        final draftEntity = DailyLogDto.fromJson({
          'id': 11,
          'logDate': '2026-10-14',
          'formStatus': 'DRAFT',
          'certificationStatus': 'NOT_READY',
        }).toEntity();
        expect(draftEntity.formStatus, FormStatus.incomplete);
        expect(draftEntity.isFormComplete, isFalse);
        expect(
          draftEntity.certificationStatus,
          CertificationStatus.uncertified,
        );
        expect(draftEntity.isCertified, isFalse);
      },
    );

    test('formIndicator object with color GREEN resolves to completed', () {
      final entity = DailyLogDto.fromJson({
        'id': 12,
        'logDate': '2026-10-14',
        'formIndicator': {
          'status': 'COMPLETE',
          'color': 'GREEN',
          'positive': true,
        },
      }).toEntity();
      expect(entity.formStatus, FormStatus.completed);
      expect(entity.isFormComplete, isTrue);
    });

    test('formIndicator object with color RED resolves to incomplete', () {
      final entity = DailyLogDto.fromJson({
        'id': 13,
        'logDate': '2026-10-14',
        'formIndicator': {'status': 'DRAFT', 'color': 'RED', 'positive': false},
      }).toEntity();
      expect(entity.formStatus, FormStatus.incomplete);
      expect(entity.isFormComplete, isFalse);
    });

    test(
      'documented READY/REVOKED certificationStatus and INVALID formStatus map correctly',
      () {
        final ready = DailyLogDto.fromJson({
          'id': 20,
          'logDate': '2026-10-16',
          'formStatus': 'COMPLETE',
          'certificationStatus': 'READY',
        }).toEntity();
        expect(ready.certificationStatus, CertificationStatus.uncertified);
        expect(ready.isCertified, isFalse);

        final revoked = DailyLogDto.fromJson({
          'id': 21,
          'logDate': '2026-10-16',
          'formStatus': 'INVALID',
          'certificationStatus': 'REVOKED',
        }).toEntity();
        expect(revoked.formStatus, FormStatus.incomplete);
        expect(revoked.isFormComplete, isFalse);
        expect(
          revoked.certificationStatus,
          CertificationStatus.reCertificationRequired,
        );
        expect(revoked.isCertified, isFalse);
      },
    );
  });
}

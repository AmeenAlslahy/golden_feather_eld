import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/logs/data/models/daily_log_dto.dart';

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

    test('missing logDate throws FormatException, does not silently become now', () {
      final json = {
        'id': 1,
        'uniqueId': 'T-1',
        // 'logDate' is missing
      };

      expect(() => DailyLogDto.fromJson(json), throwsA(isA<FormatException>()));
    });

    test('invalid logDate throws FormatException, does not silently become now', () {
      final json = {
        'id': 1,
        'uniqueId': 'T-1',
        'logDate': 'INVALID_DATE',
      };

      final dto = DailyLogDto.fromJson(json);
      expect(() => dto.toEntity(), throwsA(isA<FormatException>()));
    });
  });
}

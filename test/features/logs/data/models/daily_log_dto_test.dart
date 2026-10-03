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

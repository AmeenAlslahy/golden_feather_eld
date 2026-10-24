import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/models/dvir_dto.dart';

void main() {
  group('DvirDto defect aggregation', () {
    test('flat duplicates of nested defects are ignored', () {
      final dto = DvirDto.fromJson({
        'id': 100,
        'status': 'Has Defects',
        'defectsCount': 2,
        'defects': [
          {
            'itemCode': 'TIRES',
            'itemName': 'Tires',
            'category': 'VEHICLE',
            'description': 'worn',
          },
          {
            'itemCode': 'TR_BRAKES',
            'itemName': 'Brakes',
            'category': 'TRAILER',
            'description': 'leak',
          },
        ],
        'vehicle': {
          'uniqueId': 'TRK-1',
          'detects': [
            {
              'itemCode': 'TIRES',
              'itemName': 'Tires',
              'category': 'VEHICLE',
              'description': 'worn',
            },
          ],
        },
        'trailers': [
          {
            'trailerNumber': 'TR-1',
            'detects': [
              {
                'itemCode': 'TR_BRAKES',
                'itemName': 'Brakes',
                'category': 'TRAILER',
                'description': 'leak',
              },
            ],
          },
          {
            'trailerNumber': 'TR-2',
            'detects': [
              {
                'itemCode': 'TR_LIGHTS',
                'itemName': 'Lights',
                'category': 'TRAILER',
                'description': 'out',
              },
            ],
          },
        ],
      });

      expect(dto.defects.map((d) => d.itemCode), [
        'TIRES',
        'TR_BRAKES',
        'TR_LIGHTS',
      ]);
      expect(dto.defectsCount, 3);
      expect(dto.hasDefects, isTrue);
      expect(dto.trailers.map((t) => t.trailerNumber), ['TR-1', 'TR-2']);
    });

    test('a repeated nested defect on two trailers is preserved', () {
      final dto = DvirDto.fromJson({
        'id': 101,
        'trailers': [
          {
            'trailerNumber': 'TR-1',
            'detects': [
              {'itemCode': 'TR_TIRES', 'itemName': 'Tires'},
            ],
          },
          {
            'trailerNumber': 'TR-2',
            'detects': [
              {'itemCode': 'TR_TIRES', 'itemName': 'Tires'},
            ],
          },
        ],
      });

      expect(dto.defects.length, 2);
      expect(dto.defectsCount, 2);
    });

    test('uses the server count when the summary has no defect rows', () {
      final dto = DvirDto.fromJson({
        'id': 102,
        'defectsCount': 4,
        'hasDefects': true,
      });

      expect(dto.defects, isEmpty);
      expect(dto.defectsCount, 4);
      expect(dto.hasDefects, isTrue);
    });

    test('does not double count a flat-only payload', () {
      final dto = DvirDto.fromJson({
        'id': 103,
        'defectsCount': 1,
        'defects': [
          {'itemCode': 'BRAKES', 'itemName': 'Brakes'},
        ],
      });

      expect(dto.defects.length, 1);
      expect(dto.defectsCount, 1);
    });
  });
}

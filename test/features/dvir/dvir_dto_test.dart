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

  group('DvirDto defect id preservation & location shape', () {
    test('defect row ids survive parsing (nested, trailer, and flat)', () {
      final dto = DvirDto.fromJson({
        'id': 110,
        'vehicle': {
          'uniqueId': 'TRK-9',
          'detects': [
            {'id': 8, 'itemName': 'Lights'},
          ],
        },
        'trailers': [
          {
            'trailerNumber': 'TR-1',
            'detects': [
              {'id': 9, 'itemName': 'Tires'},
            ],
          },
        ],
        'defects': [
          {'id': 7, 'itemCode': 'BRAKES', 'itemName': 'Brakes'},
        ],
      });

      // الترتيب: المتداخل أولاً ثم المسطح غير المكرر.
      expect(dto.defects.map((d) => d.id), [8, 9, 7]);
    });

    test('a defect row without an id keeps it null', () {
      final dto = DvirDto.fromJson({
        'id': 111,
        'defects': [
          {'itemName': 'Brakes'},
        ],
      });

      expect(dto.defects.single.id, isNull);
    });

    test('a string id is parsed, a non-numeric id stays null', () {
      final dto = DvirDto.fromJson({
        'id': 114,
        'defects': [
          {'id': '42', 'itemName': 'Brakes'},
          {'id': 'oops', 'itemName': 'Lights'},
        ],
      });

      expect(dto.defects.map((d) => d.id), [42, null]);
    });

    test('location as coordinate map is read as "lat, lon" text', () {
      final dto = DvirDto.fromJson({
        'id': 112,
        'location': {'latitude': 24.7136, 'longitude': 46.6753},
      });

      expect(dto.location, '24.7136, 46.6753');
    });

    test('location string passes through untouched', () {
      final dto = DvirDto.fromJson({
        'id': 113,
        'location': 'Riyadh, Exit 5',
      });

      expect(dto.location, 'Riyadh, Exit 5');
    });

    test('a location map missing a coordinate reads as null', () {
      final dto = DvirDto.fromJson({
        'id': 115,
        'location': {'latitude': 24.7136},
      });

      expect(dto.location, isNull);
    });
  });
}

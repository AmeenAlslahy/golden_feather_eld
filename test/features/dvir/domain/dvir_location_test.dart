import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/dvir/domain/dvir_location.dart';

void main() {
  group('dvirCoordinatesFrom', () {
    test('accepts a usable fix and exposes the wire shape', () {
      final coordinates = dvirCoordinatesFrom(21.2356, -86.7451);
      expect(coordinates, isNotNull);
      expect(coordinates!.toWire(), {
        'latitude': 21.2356,
        'longitude': -86.7451,
      });
    });

    test('rejects missing, non-finite, and the 0,0 sentinel', () {
      expect(dvirCoordinatesFrom(null, 1), isNull);
      expect(dvirCoordinatesFrom(1, null), isNull);
      expect(dvirCoordinatesFrom(double.nan, 1), isNull);
      expect(dvirCoordinatesFrom(1, double.infinity), isNull);
      expect(dvirCoordinatesFrom(0, 0), isNull);
    });
  });

  group('location field text', () {
    test('formats a fix as "lat, lon" and parses it back', () {
      const coordinates = DvirCoordinates(
        latitude: 21.2356,
        longitude: -86.7451,
      );
      final text = formatDvirLocationText(coordinates);
      expect(text, '21.2356, -86.7451');
      expect(parseDvirLocationText(text), coordinates);
    });

    test('free text or a half pair is not a coordinate pair', () {
      expect(parseDvirLocationText('Riyadh, Exit 5 North'), isNull);
      expect(parseDvirLocationText('24.7136, unknown'), isNull);
      expect(parseDvirLocationText('24.7136'), isNull);
      expect(parseDvirLocationText('   '), isNull);
      expect(parseDvirLocationText(null), isNull);
    });

    test('the 0,0 sentinel is not parsed as a fix', () {
      expect(parseDvirLocationText('0, 0'), isNull);
    });
  });
}

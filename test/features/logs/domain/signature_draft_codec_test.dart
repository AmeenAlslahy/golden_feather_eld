import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/logs/domain/signature_draft_codec.dart';
import 'package:signature/signature.dart';

void main() {
  group('SignatureDraftCodec', () {
    test('encodes and decodes points accurately', () {
      final points = [
        Point(const Offset(12.5, 34.0), PointType.tap, 0.8),
        Point(const Offset(56.2, 78.9), PointType.move, 1.0),
      ];

      final encoded = SignatureDraftCodec.encodePoints(points);
      expect(encoded, contains('"x":12.5'));
      expect(encoded, contains('"t":"tap"'));
      expect(encoded, contains('"p":0.8'));

      final decoded = SignatureDraftCodec.decodePoints(encoded);
      expect(decoded.length, 2);
      expect(decoded[0].offset.dx, 12.5);
      expect(decoded[0].offset.dy, 34.0);
      expect(decoded[0].type, PointType.tap);
      expect(decoded[0].pressure, 0.8);

      expect(decoded[1].offset.dx, 56.2);
      expect(decoded[1].offset.dy, 78.9);
      expect(decoded[1].type, PointType.move);
      expect(decoded[1].pressure, 1.0);
    });

    test('handles empty and null safely', () {
      expect(SignatureDraftCodec.encodePoints([]), '[]');
      expect(SignatureDraftCodec.decodePoints(null), isEmpty);
      expect(SignatureDraftCodec.decodePoints(''), isEmpty);
      expect(SignatureDraftCodec.decodePoints('invalid-json'), isEmpty);
      expect(SignatureDraftCodec.decodePoints('{}'), isEmpty);
    });
  });
}

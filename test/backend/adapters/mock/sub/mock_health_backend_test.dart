import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_health_backend.dart';

void main() {
  const backend = MockHealthBackend();

  group('MockHealthBackend.checkLiveness', () {
    test('returns success', () async {
      final result = await backend.checkLiveness();
      expect(result.isSuccess, isTrue);
    });
  });

  group('MockHealthBackend.checkDetailed', () {
    test('returns detailed fixture', () async {
      final result = await backend.checkDetailed();

      result.tap(onSuccess: (data) {
        expect(data['database'], isNotNull);
        expect(data['storage'], isNotNull);
        expect(data['scheduler'], isNotNull);
      });
    });

    test('returns independent copies (no shared state)', () async {
      final first = await backend.checkDetailed();
      final second = await backend.checkDetailed();

      first.tap(onSuccess: (a) {
        second.tap(onSuccess: (b) {
          expect(a, isNot(same(b)));
        });
      });
    });
  });
}

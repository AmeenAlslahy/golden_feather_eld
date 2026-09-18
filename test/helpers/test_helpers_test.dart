import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'test_helpers.dart';

void main() {
  group('expectSuccess', () {
    test('returns value on success', () {
      final value = expectSuccess(ok(42));
      expect(value, 42);
    });

    test('fails on error', () {
      expect(
        () => expectSuccess(err<int>(
          const NetworkError(code: 'x', l10nKey: 'y'),
        )),
        throwsA(isA<TestFailure>()),
      );
    });
  });

  group('expectError', () {
    test('returns error on failure', () {
      const e = NetworkError(code: 'x', l10nKey: 'y');
      final error = expectError(err<int>(e));
      expect(error, e);
    });

    test('fails on success', () {
      expect(
        () => expectError(ok(42)),
        throwsA(isA<TestFailure>()),
      );
    });
  });
}

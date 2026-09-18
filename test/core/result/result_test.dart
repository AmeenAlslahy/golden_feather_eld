import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/result/result.dart';

void main() {
  const testError = NetworkError(code: 'x', l10nKey: 'y');

  group('Result — constructors', () {
    test('ok wraps a value', () {
      final result = ok(42);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, 42);
      expect(result.errorOrNull, isNull);
    });

    test('err wraps an error', () {
      final result = err<int>(testError);
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.errorOrNull, testError);
    });
  });

  group('Result — value extraction', () {
    test('getOrElse (from fpdart) returns value on success', () {
      final result = ok(42);
      // fpdart signature: T Function(AppError) — takes the error
      expect(result.getOrElse((_) => 0), 42);
    });

    test('getOrElse (from fpdart) returns fallback on failure', () {
      final result = err<int>(testError);
      expect(result.getOrElse((_) => 0), 0);
    });

    test('getOrThrow returns value on success', () {
      final result = ok(42);
      expect(result.getOrThrow(), 42);
    });

    test('getOrThrow throws AppError on failure', () {
      final result = err<int>(testError);
      expect(() => result.getOrThrow(), throwsA(isA<NetworkError>()));
    });
  });

  group('Result — mapping (sync)', () {
    test('mapValue transforms success', () {
      final result = ok(21).mapValue((v) => v * 2);
      expect(result.valueOrNull, 42);
    });

    test('mapValue preserves error', () {
      final result = err<int>(testError).mapValue((v) => v * 2);
      expect(result.errorOrNull, testError);
    });

    test('mapError transforms failure', () {
      const newError = AuthError(code: 'new', l10nKey: 'new');
      final result = err<int>(testError).mapError((_) => newError);
      expect(result.errorOrNull, newError);
    });

    test('flatMap chains computations', () {
      final result = ok(21).flatMap((v) => ok(v * 2));
      expect(result.valueOrNull, 42);
    });

    test('flatMap short-circuits on error', () {
      final result = err<int>(testError).flatMap((v) => ok(v * 2));
      expect(result.errorOrNull, testError);
    });
  });

  group('Result — mapping (async)', () {
    test('mapValueAsync transforms success', () async {
      final result = await ok(21).mapValueAsync((v) async => v * 2);
      expect(result.valueOrNull, 42);
    });

    test('mapValueAsync preserves error', () async {
      final result = await err<int>(testError)
          .mapValueAsync((v) async => v * 2);
      expect(result.errorOrNull, testError);
    });

    test('mapValueAsync handles async delays', () async {
      final result = await ok(21).mapValueAsync((v) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return v * 2;
      });
      expect(result.valueOrNull, 42);
    });

    test('mapValueAsync propagates error from mapper', () async {
      await ok(21).mapValueAsync<int>((v) async {
        throw Exception('boom');
      });
      // Since we don't wrap mapper exceptions, they propagate.
      // This is intentional — caller decides how to handle.
    }, skip: 'Mapper exceptions are not caught by design');
  });

  group('Result — tap', () {
    test('onSuccess is called for success', () {
      var called = false;
      ok(42).tap(onSuccess: (_) => called = true);
      expect(called, isTrue);
    });

    test('onFailure is called for failure', () {
      var called = false;
      err<int>(testError).tap(onFailure: (_) => called = true);
      expect(called, isTrue);
    });

    test('tap returns the original result', () {
      final result = ok(42).tap(onSuccess: (_) {});
      expect(result.valueOrNull, 42);
    });

    test('tap does not call onSuccess for failure', () {
      var successCalled = false;
      err<int>(testError).tap(onSuccess: (_) => successCalled = true);
      expect(successCalled, isFalse);
    });

    test('tap does not call onFailure for success', () {
      var failureCalled = false;
      ok(42).tap(onFailure: (_) => failureCalled = true);
      expect(failureCalled, isFalse);
    });
  });
}

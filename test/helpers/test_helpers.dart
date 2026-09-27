import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/result/result.dart';

/// Asserts that a [Result] is a success and returns its value.
///
/// Fails the test with a readable message if the result is an error.
T expectSuccess<T>(Result<T> result) {
  return result.fold(
    (error) => fail(
      'Expected success, but got error: '
      '${error.runtimeType} '
      '(code: ${error.code}, l10nKey: ${error.l10nKey})',
    ),
    (value) => value,
  );
}

/// Asserts that a [Result] is an error and returns it.
///
/// Fails the test if the result is a success.
AppError expectError<T>(Result<T> result) {
  return result.fold(
    (error) => error,
    (value) => fail('Expected error, but got success: $value'),
  );
}

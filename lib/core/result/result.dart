/// Application-wide result type.
///
/// A [Result] is either a success value `T` or an [AppError].
/// It replaces ad-hoc `null` returns, exceptions, and `Map`-based
/// error signaling.
///
/// **Rule:** Every method that can fail returns `Result<T>`.
/// **Rule:** Never throw across layer boundaries.
library;

import 'package:fpdart/fpdart.dart' as fp;

import '../error/app_error.dart';

/// A result that is either a successful `T` or a failed [AppError].
typedef Result<T> = fp.Either<AppError, T>;

/// Convenience alias for an async result.
typedef ResultFuture<T> = Future<Result<T>>;

// ============================================================================
// Constructors
// ============================================================================

/// Creates a successful [Result].
Result<T> ok<T>(T value) => fp.Right(value);

/// Creates a failed [Result].
Result<T> err<T>(AppError error) => fp.Left(error);

// ============================================================================
// Extensions
// ============================================================================

/// Extensions on synchronous [Result].
///
/// **Note:** We don't override `getOrElse` because `fpdart.Either`
/// already provides one with the signature `T Function(AppError)`. Use
/// that directly.
extension ResultX<T> on Result<T> {
  /// Returns the successful value, or `null` if failed.
  T? get valueOrNull => fold((_) => null, (v) => v);

  /// Returns the error, or `null` if successful.
  AppError? get errorOrNull => fold((e) => e, (_) => null);

  /// Whether the result is a success.
  bool get isSuccess => isRight();

  /// Whether the result is a failure.
  bool get isFailure => isLeft();

  /// Throws [error] if failed, otherwise returns the value.
  ///
  /// **Rule:** Only use at composition boundaries (`main`, tests).
  /// Never in application logic.
  T getOrThrow() => fold((e) => throw e, (v) => v);

  /// Maps the successful value using [mapper].
  Result<R> mapValue<R>(R Function(T value) mapper) {
    return fold((e) => fp.Left(e), (v) => fp.Right(mapper(v)));
  }

  /// Maps the successful value asynchronously.
  ///
  /// Useful when the mapping itself requires an async operation
  /// (e.g. another API call, disk write).
  ResultFuture<R> mapValueAsync<R>(Future<R> Function(T value) mapper) async {
    return fold(
      (e) => fp.Left<AppError, R>(e),
      (v) async => fp.Right<AppError, R>(await mapper(v)),
    );
  }

  /// Maps the error using [mapper].
  Result<T> mapError(AppError Function(AppError error) mapper) {
    return fold((e) => fp.Left(mapper(e)), (v) => fp.Right(v));
  }

  /// Chains another [Result] computation.
  Result<R> flatMap<R>(Result<R> Function(T value) mapper) {
    return fold((e) => fp.Left(e), (v) => mapper(v));
  }

  /// Runs [onSuccess] or [onFailure], returning this result.
  ///
  /// Useful for side effects (logging, analytics) in a chain.
  Result<T> tap({
    void Function(T value)? onSuccess,
    void Function(AppError error)? onFailure,
  }) {
    fold(
      (e) {
        onFailure?.call(e);
        return null;
      },
      (v) {
        onSuccess?.call(v);
        return null;
      },
    );
    return this;
  }
}

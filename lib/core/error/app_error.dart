/// Application-wide error hierarchy.
///
/// All errors in the system are represented as [AppError] instances.
/// This gives us:
///   - Compile-time exhaustiveness (sealed class).
///   - Separation of machine-readable [code] from user-facing [l10nKey].
///   - A single place to attach debugging context.
///
/// **Rule:** No raw exceptions should escape the backend layer.
/// They must be mapped to an [AppError] subclass via an error mapper.
///
/// **Rule:** Every [AppError] subclass must be constructible as `const`.
library;

/// Severity of an error, used for logging and UI presentation.
enum ErrorSeverity {
  /// Informational; user should not be alarmed.
  info,

  /// Something unexpected but recoverable.
  warning,

  /// A recoverable error the user must be informed about.
  error,

  /// Unrecoverable; app may need to restart or show a blocking screen.
  fatal,
}

/// Base class for all application errors.
///
/// Subclasses must be `final` (not `sealed`) so that external code
/// can pattern-match on the sealed base without knowing all subclasses.
sealed class AppError {
  /// Machine-readable error code (e.g. `network.timeout`, `auth.expired`).
  ///
  /// Used for:
  ///   - Logging and analytics.
  ///   - Filtering / branching logic in tests.
  ///   - Error registry lookups.
  ///
  /// **Never** shown to the user.
  final String code;

  /// Localization key for user-facing display.
  ///
  /// Resolved via `l10n` to produce the actual message.
  /// If the key is missing from `l10n`, the UI falls back to `code`.
  final String l10nKey;

  /// Severity for logging and UI.
  final ErrorSeverity severity;

  /// Original exception that caused this error, if any.
  ///
  /// **Never** shown to the user. Used for debugging and crash reporting.
  final Object? cause;

  /// Original stack trace, if available.
  final StackTrace? stackTrace;

  /// Additional context for debugging and analytics.
  ///
  /// Examples:
  ///   - `{'statusCode': 500, 'endpoint': '/eld/status'}`
  ///   - `{'field': 'email'}`
  ///
  /// **Rule:** Never include secrets (tokens, passwords) in context.
  final Map<String, dynamic>? context;

  const AppError({
    required this.code,
    required this.l10nKey,
    required this.severity,
    this.cause,
    this.stackTrace,
    this.context,
  });

  /// Returns a copy with additional context merged in.
  ///
  /// Useful for enriching an error as it propagates up the stack.
  AppError withContext(Map<String, dynamic> extra) {
    return _copyWith(context: {...?context, ...extra});
  }

  /// Returns a copy with cause and stackTrace attached.
  AppError withCause(Object cause, [StackTrace? stackTrace]) {
    return _copyWith(cause: cause, stackTrace: stackTrace);
  }

  /// Internal copy helper. Subclasses override.
  AppError _copyWith({
    Object? cause,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  });

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType($code)');
    if (context != null && context!.isNotEmpty) {
      buffer.write(' context=$context');
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppError &&
            runtimeType == other.runtimeType &&
            code == other.code &&
            l10nKey == other.l10nKey &&
            severity == other.severity;
  }

  @override
  int get hashCode => Object.hash(runtimeType, code, l10nKey, severity);
}

// ============================================================================
// Network errors
// ============================================================================

/// The device has no internet connection, or the server is unreachable.
final class NetworkError extends AppError {
  const NetworkError({
    required super.code,
    required super.l10nKey,
    super.cause,
    super.stackTrace,
    super.context,
  }) : super(severity: ErrorSeverity.warning);

  @override
  NetworkError _copyWith({
    Object? cause,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return NetworkError(
      code: code,
      l10nKey: l10nKey,
      cause: cause ?? this.cause,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
    );
  }
}

// ============================================================================
// Auth errors
// ============================================================================

/// Generic authentication failure (login rejected, invalid credentials).
final class AuthError extends AppError {
  const AuthError({
    required super.code,
    required super.l10nKey,
    super.cause,
    super.stackTrace,
    super.context,
  }) : super(severity: ErrorSeverity.warning);

  @override
  AuthError _copyWith({
    Object? cause,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return AuthError(
      code: code,
      l10nKey: l10nKey,
      cause: cause ?? this.cause,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
    );
  }
}

/// The session has expired and the user must log in again.
final class SessionExpiredError extends AppError {
  const SessionExpiredError({
    super.code = 'auth.session.expired',
    super.l10nKey = 'sessionExpired',
    super.cause,
    super.stackTrace,
    super.context,
  }) : super(severity: ErrorSeverity.warning);

  @override
  SessionExpiredError _copyWith({
    Object? cause,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return SessionExpiredError(
      code: code,
      l10nKey: l10nKey,
      cause: cause ?? this.cause,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
    );
  }
}

// ============================================================================
// Validation errors
// ============================================================================

/// Input validation failed (form fields, business rule checks).
///
/// When the error concerns specific form fields, [fieldErrors] maps
/// field names to error messages (l10n keys).
final class ValidationError extends AppError {
  final Map<String, String>? fieldErrors;

  const ValidationError({
    required super.code,
    required super.l10nKey,
    super.cause,
    super.stackTrace,
    super.context,
    this.fieldErrors,
  }) : super(severity: ErrorSeverity.warning);

  @override
  ValidationError _copyWith({
    Object? cause,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return ValidationError(
      code: code,
      l10nKey: l10nKey,
      cause: cause ?? this.cause,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
      fieldErrors: fieldErrors,
    );
  }
}

// ============================================================================
// Permission errors
// ============================================================================

/// Access denied (403). User is authenticated but not authorized.
final class PermissionError extends AppError {
  const PermissionError({
    super.code = 'auth.forbidden',
    super.l10nKey = 'permissionDenied',
    super.cause,
    super.stackTrace,
    super.context,
  }) : super(severity: ErrorSeverity.warning);

  @override
  PermissionError _copyWith({
    Object? cause,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return PermissionError(
      code: code,
      l10nKey: l10nKey,
      cause: cause ?? this.cause,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
    );
  }
}

// ============================================================================
// Not found
// ============================================================================

/// Resource not found (404).
final class NotFoundError extends AppError {
  const NotFoundError({
    super.code = 'resource.notFound',
    super.l10nKey = 'notFound',
    super.cause,
    super.stackTrace,
    super.context,
  }) : super(severity: ErrorSeverity.warning);

  @override
  NotFoundError _copyWith({
    Object? cause,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return NotFoundError(
      code: code,
      l10nKey: l10nKey,
      cause: cause ?? this.cause,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
    );
  }
}

// ============================================================================
// Conflict
// ============================================================================

/// Resource conflict (409). E.g. duplicate trailer number, already certified.
final class ConflictError extends AppError {
  const ConflictError({
    required super.code,
    required super.l10nKey,
    super.cause,
    super.stackTrace,
    super.context,
  }) : super(severity: ErrorSeverity.warning);

  @override
  ConflictError _copyWith({
    Object? cause,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return ConflictError(
      code: code,
      l10nKey: l10nKey,
      cause: cause ?? this.cause,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
    );
  }
}

// ============================================================================
// Unsupported capability
// ============================================================================

/// The backend does not support the requested capability.
///
/// This is a **configuration** error, not a user error. It indicates
/// the client requested an endpoint the backend hasn't implemented,
/// or the user's server doesn't support the feature.
final class UnsupportedCapabilityError extends AppError {
  /// Capability identifier that was requested (e.g. `hos.reports`).
  final String? capability;

  const UnsupportedCapabilityError({
    super.code = 'backend.unsupported',
    super.l10nKey = 'featureNotSupported',
    super.cause,
    super.stackTrace,
    super.context,
    this.capability,
  }) : super(severity: ErrorSeverity.error);

  @override
  UnsupportedCapabilityError _copyWith({
    Object? cause,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return UnsupportedCapabilityError(
      code: code,
      l10nKey: l10nKey,
      cause: cause ?? this.cause,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
      capability: capability,
    );
  }
}

// ============================================================================
// Server errors
// ============================================================================

/// Server-side error (5xx, malformed response, unexpected state).
final class ServerError extends AppError {
  /// HTTP status code, if available.
  final int? statusCode;

  const ServerError({
    required super.code,
    super.l10nKey = 'serverError',
    super.cause,
    super.stackTrace,
    super.context,
    this.statusCode,
  }) : super(severity: ErrorSeverity.error);

  @override
  ServerError _copyWith({
    Object? cause,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return ServerError(
      code: code,
      l10nKey: l10nKey,
      cause: cause ?? this.cause,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
      statusCode: statusCode,
    );
  }
}

// ============================================================================
// Time authority
// ============================================================================

/// Trusted time is unavailable. HOS calculations must be suspended.
final class TimeUnavailableError extends AppError {
  const TimeUnavailableError({
    super.code = 'time.unavailable',
    super.l10nKey = 'timeUnavailable',
    super.cause,
    super.stackTrace,
    super.context,
  }) : super(severity: ErrorSeverity.error);

  @override
  TimeUnavailableError _copyWith({
    Object? cause,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return TimeUnavailableError(
      code: code,
      l10nKey: l10nKey,
      cause: cause ?? this.cause,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
    );
  }
}

// ============================================================================
// Storage
// ============================================================================

/// Local storage failure (secure storage, Hive, SQLite).
final class StorageError extends AppError {
  const StorageError({
    required super.code,
    required super.l10nKey,
    super.cause,
    super.stackTrace,
    super.context,
  }) : super(severity: ErrorSeverity.error);

  @override
  StorageError _copyWith({
    Object? cause,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return StorageError(
      code: code,
      l10nKey: l10nKey,
      cause: cause ?? this.cause,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
    );
  }
}

// ============================================================================
// Sync
// ============================================================================

/// Offline sync failure (queue overflow, conflict, retry exhausted).
final class SyncError extends AppError {
  const SyncError({
    required super.code,
    required super.l10nKey,
    super.cause,
    super.stackTrace,
    super.context,
  }) : super(severity: ErrorSeverity.warning);

  @override
  SyncError _copyWith({
    Object? cause,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return SyncError(
      code: code,
      l10nKey: l10nKey,
      cause: cause ?? this.cause,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
    );
  }
}

// ============================================================================
// Unknown
// ============================================================================

/// Fallback error for unclassifiable failures.
///
/// **Rule:** Every `UnknownError` in production indicates a missing
/// mapper. Log it, but never construct it in application code.
final class UnknownError extends AppError {
  const UnknownError({
    required super.code,
    super.l10nKey = 'unknownError',
    super.cause,
    super.stackTrace,
    super.context,
  }) : super(severity: ErrorSeverity.fatal);

  @override
  UnknownError _copyWith({
    Object? cause,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return UnknownError(
      code: code,
      l10nKey: l10nKey,
      cause: cause ?? this.cause,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
    );
  }
}

/// Identifies the type of backend the client is talking to.
///
/// The current implementation supports only `eldEngine` (the unified
/// ELD/HOS API) and `mock` (for testing and demos).
///
/// **Extension rule:** Add new values only if the corresponding
/// [BackendAdapter] implementation is genuinely different (different
/// response envelopes, different auth, different endpoint structure).
library;

enum BackendKind {
  /// Unified ELD/HOS Engine (`/api/eld/*`).
  eldEngine,

  /// In-memory mock adapter for development and tests.
  ///
  /// Never used in production.
  mock,
}

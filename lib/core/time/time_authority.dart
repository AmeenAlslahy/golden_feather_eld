/// Trusted time abstraction.
///
/// **Why this exists:**
/// - FMCSA §4.3.2.2 requires ELD to use a time source that cannot be
///   manipulated by the driver.
/// - The device clock is trivially manipulable.
/// - A server-synced or NTP-synced authority is required in production.
///
/// **Design:**
/// - The interface is pure — no I/O, no platform channels.
/// - Implementations decide the sync mechanism.
/// - Callers use `nowUtc()` for timestamps and `monotonicElapsed` for
///   measuring durations between calls.
library;

/// Level of trust for the current time source.
///
/// Callers may refuse to compute time-sensitive results when trust is
/// below a threshold.
enum TrustLevel {
  /// No anchor established. Time is unusable.
  untrusted,

  /// Anchored to the device clock only.
  /// Suitable for development; not for production HOS.
  localDevice,

  /// Anchored to a server-provided UTC timestamp.
  /// Suitable for production.
  serverSynced,

  /// Anchored to NTP.
  /// Highest trust.
  ntpSynced,
}

/// Provides current UTC time and a monotonic clock.
abstract interface class TimeAuthority {
  /// Prepares the authority for use.
  ///
  /// Implementations may perform I/O (server fetch, NTP query). Must
  /// be called once before [nowUtc] and [monotonicElapsed] are
  /// guaranteed to be meaningful.
  ///
  /// Calling multiple times is safe (idempotent).
  Future<void> initialize();

  /// The current UTC time according to the best-known anchor.
  ///
  /// **Rule:** The returned value is always UTC (`isUtc == true`).
  /// **Rule:** If not initialized, returns `DateTime.now().toUtc()`
  /// with [trustLevel] == [TrustLevel.untrusted].
  DateTime nowUtc();

  /// Monotonic elapsed time since the authority was first anchored.
  ///
  /// **Important:** This is **not** wall-clock time. Use it to measure
  /// durations between two calls in the same session. It does not
  /// go backwards when the device clock changes.
  Duration get monotonicElapsed;

  /// The current level of trust for [nowUtc].
  TrustLevel get trustLevel;

  /// Attempts to re-synchronize with the anchor source.
  ///
  /// Useful after the app regains network connectivity.
  /// Returns `true` if a new anchor was successfully established.
  Future<bool> resync();
}

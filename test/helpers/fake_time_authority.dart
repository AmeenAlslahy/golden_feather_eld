import 'package:golden_feather_eld/core/time/time_authority.dart';

/// A [TimeAuthority] for deterministic tests.
///
/// **Not for production.** Lives under `test/helpers/` so it never ships in
/// the app bundle; import it with a relative path from any test.
///
/// **Default state:**
/// - `nowUtc()` = fixed epoch (2026-01-15T10:00:00Z).
/// - `trustLevel` = [TrustLevel.serverSynced].
///
/// Use [advance] to move time forward. Use [setTrustLevel] to change
/// the trust level.
class FakeTimeAuthority implements TimeAuthority {
  static final DateTime _defaultEpoch = DateTime.utc(2026, 1, 15, 10);

  DateTime _now;
  Duration _elapsed;
  TrustLevel _trust;
  bool _initialized = false;

  FakeTimeAuthority({
    DateTime? initialTime,
    TrustLevel initialTrust = TrustLevel.serverSynced,
  })  : _now = (initialTime ?? _defaultEpoch).toUtc(),
        _elapsed = Duration.zero,
        _trust = initialTrust;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  /// Whether [initialize] was called.
  bool get isInitialized => _initialized;

  @override
  DateTime nowUtc() => _now;

  @override
  Duration get monotonicElapsed => _elapsed;

  @override
  TrustLevel get trustLevel => _trust;

  @override
  Future<bool> resync() async => true;

  // ==========================================================================
  // Test controls
  // ==========================================================================

  /// Moves the current time and monotonic clock forward by [duration].
  void advance(Duration duration) {
    _now = _now.add(duration);
    _elapsed += duration;
  }

  /// Sets the current time without affecting the monotonic clock.
  ///
  /// Useful for simulating clock changes (e.g., manual device time
  /// adjustment).
  void setTime(DateTime newTime) {
    _now = newTime.toUtc();
  }

  /// Sets the trust level.
  void setTrustLevel(TrustLevel level) {
    _trust = level;
  }
}

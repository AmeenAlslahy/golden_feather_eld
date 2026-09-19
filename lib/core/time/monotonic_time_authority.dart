import 'time_authority.dart';

/// A [TimeAuthority] anchored to the local device clock at first use.
///
/// **Use case:** Development, tests, and offline fallback.
///
/// **Trust level:** [TrustLevel.localDevice] once initialized.
///
/// **Mechanism:**
/// - On `initialize()`, records `DateTime.now().toUtc()` as the anchor
///   and starts a [Stopwatch].
/// - `nowUtc()` = anchor + stopwatch.elapsed.
/// - `monotonicElapsed` = stopwatch.elapsed.
///
/// **Limitation:** Does not protect against device clock manipulation
/// between app launches. Suitable for development only.
class MonotonicTimeAuthority implements TimeAuthority {
  final Stopwatch _stopwatch = Stopwatch();
  DateTime? _anchorUtc;

  @override
  Future<void> initialize() async {
    if (_anchorUtc != null) return;
    _anchorUtc = DateTime.now().toUtc();
    _stopwatch
      ..reset()
      ..start();
  }

  @override
  DateTime nowUtc() {
    final anchor = _anchorUtc;
    if (anchor == null) {
      return DateTime.now().toUtc();
    }
    return anchor.add(_stopwatch.elapsed);
  }

  @override
  Duration get monotonicElapsed => _stopwatch.elapsed;

  @override
  TrustLevel get trustLevel =>
      _anchorUtc == null ? TrustLevel.untrusted : TrustLevel.localDevice;

  @override
  Future<bool> resync() async {
    // Monotonic authority cannot sync with an external source.
    // Re-anchor to the current device time.
    _anchorUtc = DateTime.now().toUtc();
    _stopwatch
      ..reset()
      ..start();
    return true;
  }
}

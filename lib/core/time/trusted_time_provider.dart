import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents the detailed state of the time trust.
enum TrustedTimeState {
  uninitialized,
  trusted,
  stale,
  invalid,
  unavailable,
}

/// Sealed class for time result to force callers to handle untrusted time explicitly.
sealed class TrustedTimeResult {}

class TrustedTimeAvailable extends TrustedTimeResult {
  final DateTime utc;
  TrustedTimeAvailable(this.utc);
}

class TrustedTimeUnavailable extends TrustedTimeResult {
  final TrustedTimeState state;
  TrustedTimeUnavailable(this.state);
}

abstract interface class TrustedTimeProvider {
  /// The current state of trust.
  TrustedTimeState get state;

  /// Returns a safe result representing whether trusted UTC is available.
  TrustedTimeResult get currentTime;

  /// Returns monotonic elapsed duration since anchor. (0 if not anchored yet).
  Duration get monotonicElapsed;

  /// Anchors the provider to a trusted server time.
  void anchor(DateTime serverUtc);
}

/// A production implementation that uses a monotonic Stopwatch.
class MonotonicTrustedTimeProvider implements TrustedTimeProvider {
  final Stopwatch _stopwatch = Stopwatch();
  DateTime? _trustedServerUtcAtSync;

  @override
  TrustedTimeState get state {
    if (_trustedServerUtcAtSync == null) return TrustedTimeState.uninitialized;

    // For now, if offline for more than 7 days, consider stale.
    if (_stopwatch.elapsed.inDays >= 7) return TrustedTimeState.stale;

    return TrustedTimeState.trusted;
  }

  @override
  void anchor(DateTime serverUtc) {
    _trustedServerUtcAtSync = serverUtc.toUtc();
    _stopwatch.reset();
    _stopwatch.start();
  }

  @override
  TrustedTimeResult get currentTime {
    final currentState = state;
    if (currentState != TrustedTimeState.trusted) {
      return TrustedTimeUnavailable(currentState);
    }

    return TrustedTimeAvailable(
        _trustedServerUtcAtSync!.add(_stopwatch.elapsed));
  }

  @override
  Duration get monotonicElapsed => _stopwatch.elapsed;
}

/// A fake implementation for deterministic testing.
class FakeTrustedTimeProvider implements TrustedTimeProvider {
  DateTime? _mockUtcTime;
  TrustedTimeState _state = TrustedTimeState.uninitialized;
  Duration _monotonicElapsed = Duration.zero;

  FakeTrustedTimeProvider({
    DateTime? initialUtcTime,
    TrustedTimeState initialState = TrustedTimeState.uninitialized,
  }) {
    if (initialUtcTime != null) {
      _mockUtcTime = initialUtcTime.toUtc();
      _state = initialState == TrustedTimeState.uninitialized
          ? TrustedTimeState.trusted
          : initialState;
    } else {
      _state = initialState;
    }
  }

  @override
  TrustedTimeState get state => _state;

  @override
  TrustedTimeResult get currentTime {
    if (_state != TrustedTimeState.trusted || _mockUtcTime == null) {
      return TrustedTimeUnavailable(_state);
    }
    return TrustedTimeAvailable(_mockUtcTime!);
  }

  @override
  Duration get monotonicElapsed => _monotonicElapsed;

  @override
  void anchor(DateTime serverUtc) {
    _mockUtcTime = serverUtc.toUtc();
    _state = TrustedTimeState.trusted;
    _monotonicElapsed = Duration.zero;
  }

  /// TEST ONLY: Advance the fake clock.
  void advance(Duration duration) {
    if (_mockUtcTime != null) {
      _mockUtcTime = _mockUtcTime!.add(duration);
    }
    _monotonicElapsed += duration;
  }

  /// TEST ONLY: Set state manually.
  void setState(TrustedTimeState newState) {
    _state = newState;
  }
}

final trustedTimeProvider = Provider<TrustedTimeProvider>((ref) {
  // We can return a MonotonicTrustedTimeProvider instance here.
  return MonotonicTrustedTimeProvider();
});

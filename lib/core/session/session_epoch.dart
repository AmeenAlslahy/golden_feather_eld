/// Process-wide session generation for P0 cross-account isolation (Stage 1).
///
/// A single monotonic counter owned by [AuthNotifier]. It is bumped **only**
/// on real identity boundaries (logout start, forced logout, session
/// revocation for the *current* epoch, successful login). Profile refreshes,
/// token refreshes for the same user, offline session restoration and failed
/// logins never bump it.
///
/// Two propagation channels (kept in sync by [AuthNotifier]):
/// - [SessionEpoch.current] — synchronous static read for layers that cannot
///   `ref.watch` (notably [AuthInterceptor], which tags every HTTP request
///   with the epoch that created it).
/// - `AuthState.sessionEpoch` — Riverpod snapshot so providers rebuild and
///   can fence late async responses (`sessionEpochProvider`).
///
/// The epoch is an *invalidation* signal, never an ownership proof:
/// proving who owns data is the job of `driverId`.
abstract final class SessionEpoch {
  static int _value = 0;

  /// Current generation. Reads are cheap and synchronous.
  static int get current => _value;

  /// Move to the next generation. Call only on identity boundaries.
  static int bump() => ++_value;

  /// Test-only reset so characterization tests are hermetic.
  static void resetForTests() {
    _value = 0;
  }
}

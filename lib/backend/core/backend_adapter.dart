library;

import 'backend_identity.dart';

/// Contract for a backend adapter.
///
/// A `BackendAdapter` is an **aggregator**: it groups the individual
/// backend contracts (AccountBackend, DailyLogsBackend, etc.) behind
/// a single interface.
///
/// **Why aggregation?**
/// Features need access to multiple contracts, but they should not
/// depend on each contract directly. Aggregating them through
/// [BackendAdapter] allows the composition root to swap the entire
/// backend (real → mock) with a single override.
///
/// **Scope in T1.5:**
/// The 19 individual contracts are added in T1.6. This task defines
/// the shell (identity + dispose) only.
///
/// **Rule:** Adapters must be pure aggregators. No business logic.

abstract class BackendAdapter {
  /// Metadata describing this adapter instance.
  BackendIdentity get identity;

  /// Whether this adapter is the mock backend.
  bool get isMock => identity.isMock;

  /// Releases any resources held by this adapter.
  ///
  /// Called by [BackendRegistry.disposeAll] when the adapter is no
  /// longer needed (app shutdown, backend switch).
  Future<void> dispose();
}

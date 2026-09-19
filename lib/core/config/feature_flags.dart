import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feature flags control the rollout of new implementations.
///
/// **Sources (by priority):**
/// 1. Riverpod override (in tests).
/// 2. `--dart-define=USE_NEW_STATUS_DASHBOARD=true` (build-time).
/// 3. Default value (false).
///
/// **Rule:** When a flag is removed (end of rollout), delete the flag
/// and the corresponding legacy code path in the same PR.
class FeatureFlags {
  /// Enables the new `StatusDashboardPage` (Phase 2).
  /// When `false`, `HomePage` falls back to the legacy `HosPage`.
  final bool useNewStatusDashboard;

  const FeatureFlags({
    this.useNewStatusDashboard = true,
  });

  /// Reads flags from `--dart-define`.
  factory FeatureFlags.fromEnvironment() {
    return const FeatureFlags(
      useNewStatusDashboard: bool.fromEnvironment(
        'USE_NEW_STATUS_DASHBOARD',
        defaultValue: true,
      ),
    );
  }
}

/// Global feature flags provider.
///
/// Override in tests:
/// ```dart
/// ProviderScope(
///   overrides: [
///     featureFlagsProvider.overrideWithValue(
///       const FeatureFlags(useNewStatusDashboard: true),
///     ),
///   ],
///   child: ...,
/// );
/// ```
final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  return FeatureFlags.fromEnvironment();
});

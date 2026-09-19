import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'monotonic_time_authority.dart';
import 'time_authority.dart';

/// The app-wide [TimeAuthority] provider.
///
/// **Default:** [MonotonicTimeAuthority].
///
/// **Override in production:** Replace with a server-synced or
/// NTP-synced authority (Phase 3.2).
///
/// **Override in tests:**
/// ```dart
/// ProviderScope(
///   overrides: [
///     timeAuthorityProvider.overrideWithValue(
///       FakeTimeAuthority()..advance(const Duration(hours: 1)),
///     ),
///   ],
///   child: ...,
/// );
/// ```
final timeAuthorityProvider = Provider<TimeAuthority>((ref) {
  final authority = MonotonicTimeAuthority();
  // Fire-and-forget: initialize in the background.
  // Safe because `nowUtc()` falls back to `DateTime.now()` until
  // initialized.
  authority.initialize();
  return authority;
});

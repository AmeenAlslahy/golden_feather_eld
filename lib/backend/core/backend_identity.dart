import 'backend_kind.dart';

/// Immutable metadata describing a backend instance.
///
/// This is a **pure value object**. It carries no logic.
/// It is created once (in the composition root) and passed to
/// [BackendAdapter] and [BackendRegistry].
///
/// **Rule:** The [baseUrl] is never hardcoded. It comes from
/// user configuration (Server Configuration screen).
class BackendIdentity {
  /// Unique identifier for this backend instance.
  ///
  /// Format: `<kind>:<baseUrl>`. Example: `eldEngine:https://api.example.com/api`.
  ///
  /// **Why include URL?** To allow multiple instances of the same
  /// kind (e.g., testing against staging and production in the same
  /// session — a dev scenario).
  final String id;

  /// The kind of backend.
  final BackendKind kind;

  /// Human-readable name shown in diagnostics.
  ///
  /// Example: `"Golden Feather ELD Server"`.
  final String displayName;

  /// Base URL including the `/api` path. No trailing slash.
  ///
  /// Example: `https://eld.example.com/api`.
  final String baseUrl;

  const BackendIdentity({
    required this.id,
    required this.kind,
    required this.displayName,
    required this.baseUrl,
  });

  /// Creates an identity for the ELD engine.
  ///
  /// The [id] is derived deterministically from [baseUrl], so two
  /// identical configs produce the same identity.
  factory BackendIdentity.eldEngine({required String baseUrl}) {
    final normalized = _normalizeUrl(baseUrl);
    return BackendIdentity(
      id: 'eldEngine:$normalized',
      kind: BackendKind.eldEngine,
      displayName: 'ELD Engine',
      baseUrl: normalized,
    );
  }

  /// Creates an identity for the mock adapter.
  factory BackendIdentity.mock() {
    return const BackendIdentity(
      id: 'mock:local',
      kind: BackendKind.mock,
      displayName: 'Demo Backend',
      baseUrl: 'mock://local',
    );
  }

  /// Whether this identity is for the mock backend.
  bool get isMock => kind == BackendKind.mock;

  /// Whether this identity is for the ELD engine.
  bool get isEldEngine => kind == BackendKind.eldEngine;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackendIdentity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BackendIdentity($id)';

  static String _normalizeUrl(String url) {
    var normalized = url.trim();
    if (!normalized.contains('://')) {
      normalized = 'https://$normalized';
    }
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}

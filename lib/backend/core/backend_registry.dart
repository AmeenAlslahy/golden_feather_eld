import 'backend_adapter.dart';
import 'backend_identity.dart';

/// Manages the lifecycle and lookup of [BackendAdapter] instances.
///
/// The registry holds a map of adapters keyed by their identity id.
/// Exactly one adapter is marked as **active**; features access it
/// via [active].
///
/// **Why a registry instead of a single adapter?**
/// - Tests may inject a mock adapter alongside a real one.
/// - Future support for multiple backends (e.g., a secondary
///   read-only source) without changing feature code.
///
/// **Rule:** The registry is created once in the composition root.
/// **Rule:** The registry never mutates after construction.
class BackendRegistry {
  /// All registered adapters, keyed by [BackendIdentity.id].
  final Map<String, BackendAdapter> _adapters;

  /// The identity of the active adapter.
  ///
  /// Must exist in [_adapters].
  final BackendIdentity activeIdentity;

  BackendRegistry._({
    required Map<String, BackendAdapter> adapters,
    required this.activeIdentity,
  }) : _adapters = Map.unmodifiable(adapters);

  /// Creates a registry from a list of adapters and an active id.
  ///
  /// Throws [ArgumentError] if:
  ///   - [adapters] is empty.
  ///   - Two adapters share the same identity id.
  ///   - [activeIdentity] is not present in [adapters].
  factory BackendRegistry({
    required List<BackendAdapter> adapters,
    required String activeId,
  }) {
    if (adapters.isEmpty) {
      throw ArgumentError('BackendRegistry requires at least one adapter.');
    }

    final map = <String, BackendAdapter>{};
    for (final adapter in adapters) {
      final id = adapter.identity.id;
      if (map.containsKey(id)) {
        throw ArgumentError(
          'Duplicate adapter id: $id. '
          'Two adapters with the same identity cannot coexist.',
        );
      }
      map[id] = adapter;
    }

    if (!map.containsKey(activeId)) {
      throw ArgumentError(
        'Active id "$activeId" not found. '
        'Available ids: ${map.keys.join(", ")}.',
      );
    }

    return BackendRegistry._(
      adapters: map,
      activeIdentity: map[activeId]!.identity,
    );
  }

  /// Convenience factory for a single-adapter registry.
  factory BackendRegistry.single(BackendAdapter adapter) {
    return BackendRegistry(
      adapters: [adapter],
      activeId: adapter.identity.id,
    );
  }

  /// The currently active adapter.
  ///
  /// This is what features access.
  BackendAdapter get active => _adapters[activeIdentity.id]!;

  /// Returns the adapter with the given [id], or `null` if missing.
  BackendAdapter? getById(String id) => _adapters[id];

  /// Returns the adapter matching the given [identity], or `null`.
  BackendAdapter? getByIdentity(BackendIdentity identity) =>
      _adapters[identity.id];

  /// All registered adapters.
  Iterable<BackendAdapter> get all => _adapters.values;

  /// Whether an adapter with the given [id] is registered.
  bool has(String id) => _adapters.containsKey(id);

  /// The number of registered adapters.
  int get length => _adapters.length;

  /// Whether this registry contains only a mock adapter.
  bool get isMockOnly => _adapters.values.every((a) => a.isMock);

  /// Disposes all registered adapters.
  ///
  /// Uses `Future.wait` so that adapters are disposed concurrently.
  /// Errors from individual adapters are collected and reported
  /// as an aggregate error.
  Future<void> disposeAll() async {
    final results = await Future.wait([
      for (final adapter in _adapters.values)
        adapter.dispose().then<Object?>(
              (_) => null,
              onError: (Object e, StackTrace st) => e,
            ),
    ]);

    final errors = results.whereType<Object>().toList();
    if (errors.isNotEmpty) {
      throw StateError(
        'Failed to dispose ${errors.length} of ${_adapters.length} adapters. '
        'Errors: $errors',
      );
    }
  }

  @override
  String toString() =>
      'BackendRegistry(active: ${activeIdentity.id}, '
      'adapters: ${_adapters.keys.join(", ")})';
}

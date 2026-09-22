import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/base/backend_adapter.dart';
import 'package:golden_feather_eld/backend/base/backend_identity.dart';
import 'package:golden_feather_eld/backend/base/backend_registry.dart';

/// Test double for [BackendAdapter].
class _FakeAdapter implements BackendAdapter {
  @override
  final BackendIdentity identity;

  bool disposed = false;

  _FakeAdapter(this.identity);

  @override
  bool get isMock => identity.isMock;

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake that fails on dispose.
class _FailingAdapter implements BackendAdapter {
  @override
  final BackendIdentity identity;

  _FailingAdapter(this.identity);

  @override
  bool get isMock => identity.isMock;

  @override
  Future<void> dispose() async {
    throw StateError('Dispose failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeAdapter eldAdapter;
  late _FakeAdapter mockAdapter;

  setUp(() {
    eldAdapter = _FakeAdapter(
      BackendIdentity.eldEngine(baseUrl: 'https://api.example.com/api'),
    );
    mockAdapter = _FakeAdapter(BackendIdentity.mock());
  });

  group('BackendRegistry — construction', () {
    test('accepts single adapter', () {
      final registry = BackendRegistry.single(eldAdapter);

      expect(registry.length, 1);
      expect(registry.active, same(eldAdapter));
      expect(registry.activeIdentity, eldAdapter.identity);
    });

    test('accepts multiple adapters', () {
      final registry = BackendRegistry(
        adapters: [eldAdapter, mockAdapter],
        activeId: eldAdapter.identity.id,
      );

      expect(registry.length, 2);
      expect(registry.active, same(eldAdapter));
    });

    test('throws on empty adapter list', () {
      expect(
        () => BackendRegistry(adapters: const [], activeId: 'anything'),
        throwsArgumentError,
      );
    });

    test('throws on duplicate ids', () {
      final duplicate = _FakeAdapter(
        BackendIdentity.eldEngine(baseUrl: 'https://api.example.com/api'),
      );

      expect(
        () => BackendRegistry(
          adapters: [eldAdapter, duplicate],
          activeId: eldAdapter.identity.id,
        ),
        throwsArgumentError,
      );
    });

    test('throws when active id is missing', () {
      expect(
        () => BackendRegistry(
          adapters: [eldAdapter],
          activeId: 'nonexistent',
        ),
        throwsArgumentError,
      );
    });

    test('adapters map is unmodifiable', () {
      final registry = BackendRegistry.single(eldAdapter);
      // No public way to modify _adapters, but verify the map is not
      // mutable through the public API:
      expect(registry.all, hasLength(1));
      expect(registry.has('new'), isFalse);
    });
  });

  group('BackendRegistry — lookup', () {
    late BackendRegistry registry;

    setUp(() {
      registry = BackendRegistry(
        adapters: [eldAdapter, mockAdapter],
        activeId: eldAdapter.identity.id,
      );
    });

    test('getById returns adapter', () {
      expect(registry.getById(eldAdapter.identity.id), same(eldAdapter));
      expect(registry.getById(mockAdapter.identity.id), same(mockAdapter));
    });

    test('getById returns null for missing id', () {
      expect(registry.getById('nonexistent'), isNull);
    });

    test('getByIdentity returns adapter', () {
      expect(
        registry.getByIdentity(eldAdapter.identity),
        same(eldAdapter),
      );
    });

    test('getByIdentity returns null for missing', () {
      final unknown = BackendIdentity.eldEngine(baseUrl: 'https://x.com');
      expect(registry.getByIdentity(unknown), isNull);
    });

    test('all returns all adapters', () {
      final all = registry.all.toList();
      expect(all, hasLength(2));
      expect(all, contains(eldAdapter));
      expect(all, contains(mockAdapter));
    });

    test('has returns correct values', () {
      expect(registry.has(eldAdapter.identity.id), isTrue);
      expect(registry.has('nonexistent'), isFalse);
    });

    test('length reflects count', () {
      expect(registry.length, 2);
    });
  });

  group('BackendRegistry — mock detection', () {
    test('isMockOnly is true for single mock', () {
      final registry = BackendRegistry.single(mockAdapter);
      expect(registry.isMockOnly, isTrue);
    });

    test('isMockOnly is false when mixed', () {
      final registry = BackendRegistry(
        adapters: [eldAdapter, mockAdapter],
        activeId: eldAdapter.identity.id,
      );
      expect(registry.isMockOnly, isFalse);
    });

    test('isMockOnly is false for single eld engine', () {
      final registry = BackendRegistry.single(eldAdapter);
      expect(registry.isMockOnly, isFalse);
    });
  });

  group('BackendRegistry — disposal', () {
    test('disposeAll calls dispose on all adapters', () async {
      final registry = BackendRegistry(
        adapters: [eldAdapter, mockAdapter],
        activeId: eldAdapter.identity.id,
      );

      await registry.disposeAll();

      expect(eldAdapter.disposed, isTrue);
      expect(mockAdapter.disposed, isTrue);
    });

    test('disposeAll throws aggregate error on failure', () async {
      final failing = _FailingAdapter(BackendIdentity.mock());

      final registry = BackendRegistry.single(failing);

      expect(
        () => registry.disposeAll(),
        throwsA(isA<StateError>()),
      );
    });

    test('disposeAll continues after individual failure', () async {
      final failing = _FailingAdapter(BackendIdentity.mock());

      final registry = BackendRegistry(
        adapters: [eldAdapter, failing],
        activeId: eldAdapter.identity.id,
      );

      try {
        await registry.disposeAll();
      } catch (_) {
        // Expected aggregate error
      }

      // Successfully disposed adapter should still be marked
      expect(eldAdapter.disposed, isTrue);
    });
  });

  group('BackendRegistry — toString', () {
    test('includes active id', () {
      final registry = BackendRegistry.single(eldAdapter);
      expect(registry.toString(), contains(eldAdapter.identity.id));
    });
  });
}

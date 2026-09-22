import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/base/backend_identity.dart';
import 'package:golden_feather_eld/backend/base/backend_kind.dart';

void main() {
  group('BackendIdentity — direct construction', () {
    test('stores all fields', () {
      const identity = BackendIdentity(
        id: 'eldEngine:https://api.example.com/api',
        kind: BackendKind.eldEngine,
        displayName: 'My Server',
        baseUrl: 'https://api.example.com/api',
      );

      expect(identity.id, 'eldEngine:https://api.example.com/api');
      expect(identity.kind, BackendKind.eldEngine);
      expect(identity.displayName, 'My Server');
      expect(identity.baseUrl, 'https://api.example.com/api');
    });
  });

  group('BackendIdentity.eldEngine', () {
    test('creates identity with normalized URL', () {
      final identity = BackendIdentity.eldEngine(
        baseUrl: 'https://api.example.com/api',
      );

      expect(identity.kind, BackendKind.eldEngine);
      expect(identity.baseUrl, 'https://api.example.com/api');
      expect(identity.id, 'eldEngine:https://api.example.com/api');
      expect(identity.displayName, 'ELD Engine');
    });

    test('adds https scheme if missing', () {
      final identity = BackendIdentity.eldEngine(
        baseUrl: 'api.example.com/api',
      );

      expect(identity.baseUrl, 'https://api.example.com/api');
    });

    test('removes trailing slash', () {
      final identity = BackendIdentity.eldEngine(
        baseUrl: 'https://api.example.com/api/',
      );

      expect(identity.baseUrl, 'https://api.example.com/api');
    });

    test('produces stable id for same input', () {
      final a = BackendIdentity.eldEngine(baseUrl: 'https://x.com/api');
      final b = BackendIdentity.eldEngine(baseUrl: 'https://x.com/api/');

      expect(a.id, b.id);
      expect(a, equals(b));
    });

    test('produces different id for different URLs', () {
      final a = BackendIdentity.eldEngine(baseUrl: 'https://x.com/api');
      final b = BackendIdentity.eldEngine(baseUrl: 'https://y.com/api');

      expect(a.id, isNot(b.id));
      expect(a, isNot(equals(b)));
    });
  });

  group('BackendIdentity.mock', () {
    test('creates mock identity', () {
      final identity = BackendIdentity.mock();

      expect(identity.kind, BackendKind.mock);
      expect(identity.id, 'mock:local');
      expect(identity.baseUrl, 'mock://local');
      expect(identity.displayName, 'Demo Backend');
    });

    test('isMock returns true', () {
      expect(BackendIdentity.mock().isMock, isTrue);
      expect(BackendIdentity.mock().isEldEngine, isFalse);
    });
  });

  group('BackendIdentity — helpers', () {
    test('isEldEngine returns true for eld engine', () {
      final identity = BackendIdentity.eldEngine(baseUrl: 'https://x.com/api');
      expect(identity.isEldEngine, isTrue);
      expect(identity.isMock, isFalse);
    });
  });

  group('BackendIdentity — equality', () {
    test('equal by id only', () {
      const a = BackendIdentity(
        id: 'same',
        kind: BackendKind.eldEngine,
        displayName: 'A',
        baseUrl: 'https://a.com',
      );
      const b = BackendIdentity(
        id: 'same',
        kind: BackendKind.mock, // different kind
        displayName: 'B', // different name
        baseUrl: 'https://b.com', // different URL
      );

      // Equal because id matches
      expect(a, equals(b));
    });

    test('different ids are not equal', () {
      const a = BackendIdentity(
        id: 'a',
        kind: BackendKind.eldEngine,
        displayName: 'X',
        baseUrl: 'https://x.com',
      );
      const b = BackendIdentity(
        id: 'b',
        kind: BackendKind.eldEngine,
        displayName: 'X',
        baseUrl: 'https://x.com',
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('BackendIdentity — toString', () {
    test('includes id', () {
      final identity = BackendIdentity.eldEngine(baseUrl: 'https://x.com/api');
      expect(identity.toString(), contains('eldEngine:https://x.com/api'));
    });
  });
}

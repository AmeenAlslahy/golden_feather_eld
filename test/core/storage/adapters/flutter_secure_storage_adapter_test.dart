import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:golden_feather_eld/core/storage/adapters/flutter_secure_storage_adapter.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late FlutterSecureStorageAdapter adapter;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    adapter = FlutterSecureStorageAdapter(mockStorage);
  });

  test('read', () async {
    when(() => mockStorage.read(key: 'key')).thenAnswer((_) async => 'value');
    final result = await adapter.read('key');
    expect(result, 'value');
    verify(() => mockStorage.read(key: 'key')).called(1);
  });

  test('write', () async {
    when(() => mockStorage.write(key: 'key', value: 'value')).thenAnswer((_) async {});
    await adapter.write('key', 'value');
    verify(() => mockStorage.write(key: 'key', value: 'value')).called(1);
  });

  test('delete', () async {
    when(() => mockStorage.delete(key: 'key')).thenAnswer((_) async {});
    await adapter.delete('key');
    verify(() => mockStorage.delete(key: 'key')).called(1);
  });

  test('containsKey', () async {
    when(() => mockStorage.containsKey(key: 'key')).thenAnswer((_) async => true);
    final result = await adapter.containsKey('key');
    expect(result, true);
    verify(() => mockStorage.containsKey(key: 'key')).called(1);
  });

  test('deleteAll', () async {
    when(() => mockStorage.deleteAll()).thenAnswer((_) async {});
    await adapter.deleteAll();
    verify(() => mockStorage.deleteAll()).called(1);
  });

  group('Keystore failure fallback without wiping data', () {
    test('read falls back gracefully to in-memory fallback on PlatformException without wiping storage', () async {
      // 1. Initial write succeeds and primes fallback
      when(() => mockStorage.write(key: 'session_token', value: 'secret123'))
          .thenAnswer((_) async {});
      await adapter.write('session_token', 'secret123');

      // 2. Subsequent read encounters KeyStore corrupt exception
      when(() => mockStorage.read(key: 'session_token'))
          .thenThrow(PlatformException(code: 'KEYSTORE_ERROR', message: 'AEADBadTagException'));

      final value = await adapter.read('session_token');

      // Value is retrieved from memory fallback
      expect(value, 'secret123');
      // Crucial: deleteAll was NEVER called
      verifyNever(() => mockStorage.deleteAll());
    });

    test('write preserves value in-memory when platform storage throws Exception', () async {
      when(() => mockStorage.write(key: 'user_data', value: 'user_json'))
          .thenThrow(PlatformException(code: 'KEYSTORE_WRITE_FAIL'));
      when(() => mockStorage.read(key: 'user_data'))
          .thenThrow(PlatformException(code: 'KEYSTORE_READ_FAIL'));

      // Write should complete without crashing caller
      await expectLater(adapter.write('user_data', 'user_json'), completes);

      // Read returns in-memory value
      final value = await adapter.read('user_data');
      expect(value, 'user_json');
      verifyNever(() => mockStorage.deleteAll());
    });

    test('delete removes from memory fallback even if platform storage throws', () async {
      when(() => mockStorage.write(key: 'k', value: 'v')).thenAnswer((_) async {});
      await adapter.write('k', 'v');

      when(() => mockStorage.delete(key: 'k')).thenThrow(PlatformException(code: 'DELETE_FAIL'));
      await expectLater(adapter.delete('k'), completes);

      when(() => mockStorage.read(key: 'k')).thenAnswer((_) async => null);
      final readBack = await adapter.read('k');
      expect(readBack, isNull);
    });
  });
}

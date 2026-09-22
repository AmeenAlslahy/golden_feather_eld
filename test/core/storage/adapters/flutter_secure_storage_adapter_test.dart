import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/storage/adapters/flutter_secure_storage_adapter.dart';
import 'package:mocktail/mocktail.dart';

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
}

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/storage/adapters/shared_preferences_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferencesAdapter adapter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'test_string': 'value', 'test_int': 42});
    adapter = await SharedPreferencesAdapter.create();
  });

  test('getString', () {
    expect(adapter.getString('test_string'), 'value');
  });

  test('setString', () async {
    await adapter.setString('new_string', 'new_value');
    expect(adapter.getString('new_string'), 'new_value');
  });

  test('getInt', () {
    expect(adapter.getInt('test_int'), 42);
  });

  test('setInt', () async {
    await adapter.setInt('new_int', 100);
    expect(adapter.getInt('new_int'), 100);
  });

  test('containsKey', () {
    expect(adapter.containsKey('test_string'), true);
    expect(adapter.containsKey('invalid_key'), false);
  });

  test('remove', () async {
    await adapter.remove('test_string');
    expect(adapter.containsKey('test_string'), false);
  });

  test('clear', () async {
    await adapter.clear();
    expect(adapter.containsKey('test_int'), false);
  });
}

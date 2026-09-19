import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/storage/ports/secure_storage_port.dart';
import 'package:golden_feather_eld/domain/config/server_config.dart';
import 'package:golden_feather_eld/features/settings/presentation/providers/server_config_providers.dart';

class FakeSecureStorage implements SecureStoragePort {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);

  @override
  Future<void> deleteAll() async => _data.clear();
}

void main() {
  late FakeSecureStorage fakeStorage;
  late ServerConfigNotifier notifier;

  setUp(() async {
    fakeStorage = FakeSecureStorage();
    // Pre-populate with valid config to test load()
    await fakeStorage.write('server_config_v1', '{"baseUrl":"https://test.com","backendType":"eld","lastTestedAt":"2023-01-01T00:00:00.000Z","isVerified":false}');
    notifier = ServerConfigNotifier(fakeStorage);
    // wait a tick for load to finish
    await Future.delayed(Duration.zero);
  });

  test('load parses existing config', () {
    expect(notifier.state, isNotNull);
    expect(notifier.state!.baseUrl, 'https://test.com');
  });

  test('save updates state and storage', () async {
    final config = ServerConfig.unverified(baseUrl: 'new.com');
    await notifier.save(config);
    expect(notifier.state!.baseUrl, 'https://new.com');
    
    final stored = await fakeStorage.read('server_config_v1');
    expect(stored, contains('https://new.com'));
  });

  test('markVerified updates state', () async {
    await notifier.markVerified();
    expect(notifier.state!.isVerified, true);
  });

  test('clear removes state and storage', () async {
    await notifier.clear();
    expect(notifier.state, isNull);
    expect(await fakeStorage.containsKey('server_config_v1'), false);
  });
}

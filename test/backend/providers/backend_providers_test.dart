import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/core/backend_registry.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/storage/ports/secure_storage_port.dart';
import 'package:golden_feather_eld/core/storage/storage_providers.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class FakeSecureStorage implements SecureStoragePort {
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> deleteAll() async {}
  @override
  Future<bool> containsKey(String key) async => false;
}

class FakeLocalStorageService extends Mock implements LocalStorageService {
  @override
  String get backendType => 'mock';
  @override
  String get serverUrl => 'https://example.com';
}

void main() {
  group('BackendProviders', () {
    test('backendRegistryProvider registers adapters', () {
      final container = ProviderContainer();
      final registry = container.read(backendRegistryProvider);

      expect(registry, isA<BackendRegistry>());
      expect(registry.all, hasLength(2));
      
      // Check that the active adapter is the mock one
      expect(registry.active.identity.id, 'mock:local');

      container.dispose();
    });

    test('activeBackendProvider defaults to mock', () {
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(FakeSecureStorage()),
          localStorageProvider.overrideWithValue(FakeLocalStorageService()),
        ],
      );
      final active = container.read(activeBackendProvider);

      expect(active, isA<MockAdapter>());

      container.dispose();
    });

    test('contract providers expose correct contracts', () {
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(FakeSecureStorage()),
          localStorageProvider.overrideWithValue(FakeLocalStorageService()),
        ],
      );

      // We know MockAdapter provides all contracts, so none of these should throw.
      expect(container.read(accountBackendProvider), isNotNull);
      expect(container.read(healthBackendProvider), isNotNull);
      expect(container.read(statusDashboardBackendProvider), isNotNull);

      expect(container.read(dailyLogsBackendProvider), isNotNull);
      expect(container.read(vehicleBackendProvider), isNotNull);
      expect(container.read(rulesEngineBackendProvider), isNotNull);

      container.dispose();
    });
  });
}

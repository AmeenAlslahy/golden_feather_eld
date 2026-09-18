import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/core/backend_registry.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';

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
      final container = ProviderContainer();
      final active = container.read(activeBackendProvider);

      expect(active, isA<MockAdapter>());

      container.dispose();
    });

    test('contract providers expose correct contracts', () {
      final container = ProviderContainer();

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

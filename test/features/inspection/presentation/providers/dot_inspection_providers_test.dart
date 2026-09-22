import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/features/inspection/presentation/providers/dot_inspection_providers.dart';

void main() {
  group('DotInspectionProviders', () {
    late MockAdapter mockAdapter;

    setUp(() {
      mockAdapter = MockAdapter();
    });

    test('dotInspectionScreenProvider fetches screen', () async {
      final container = ProviderContainer(
        overrides: [
          activeBackendProvider.overrideWithValue(mockAdapter),
        ],
      );
      addTearDown(container.dispose);

      final asyncValue = await container.read(dotInspectionScreenProvider.future);
      expect(asyncValue.carrierName, 'Golden Feather Transport');
    });

    test('dotInspectionCycleProvider fetches cycle', () async {
      final container = ProviderContainer(
        overrides: [
          activeBackendProvider.overrideWithValue(mockAdapter),
        ],
      );
      addTearDown(container.dispose);

      final asyncValue = await container.read(dotInspectionCycleProvider.future);
      expect(asyncValue.length, 8);
    });
  });
}

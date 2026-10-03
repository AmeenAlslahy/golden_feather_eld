import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/features/inspection/presentation/providers/dot_inspection_providers.dart';

class _OnlineNetwork implements NetworkInfo {
  @override
  bool get isConnected => true;
  @override
  Stream<bool> get onConnectionChange => const Stream.empty();
}

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
          networkInfoProvider.overrideWithValue(_OnlineNetwork()),
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
          networkInfoProvider.overrideWithValue(_OnlineNetwork()),
        ],
      );
      addTearDown(container.dispose);

      final asyncValue = await container.read(dotInspectionCycleProvider.future);
      expect(asyncValue.length, 8);
    });
  });
}

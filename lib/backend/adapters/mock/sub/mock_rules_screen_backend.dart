import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/rules_screen_backend.dart';

/// In-memory mock for [RulesScreenBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class MockRulesScreenBackend implements RulesScreenBackend {
  const MockRulesScreenBackend();

  @override
  Future<Result<RawJson>> getRulesScreen({DriverId? driverId}) =>
      throw UnimplementedError(
        'MockRulesScreenBackend.getRulesScreen — Phase 2',
      );

  @override
  Future<Result<RawJson>> saveRulesScreen(RawJson settings) =>
      throw UnimplementedError(
        'MockRulesScreenBackend.saveRulesScreen — Phase 2',
      );
}

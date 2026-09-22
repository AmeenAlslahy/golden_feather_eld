import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/result/result.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/rules_engine_backend.dart';

/// In-memory mock for [RulesEngineBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class MockRulesEngineBackend implements RulesEngineBackend {
  const MockRulesEngineBackend();

  @override
  Future<Result<RawJson>> getCatalog() =>
      throw UnimplementedError('MockRulesEngineBackend.getCatalog — Phase 2');

  @override
  Future<Result<RawJson>> getRuleById(RuleId ruleId) =>
      throw UnimplementedError('MockRulesEngineBackend.getRuleById — Phase 2');

  @override
  Future<Result<RawJson>> getRuleSetVersions(String ruleSetId) =>
      throw UnimplementedError(
        'MockRulesEngineBackend.getRuleSetVersions — Phase 2',
      );

  @override
  Future<Result<RawJson>> getRegulations() =>
      throw UnimplementedError(
        'MockRulesEngineBackend.getRegulations — Phase 2',
      );

  @override
  Future<Result<RawJson>> evaluateShortHaul({
    required DriverId driverId,
    required double currentLatitude,
    required double currentLongitude,
    required double terminalLatitude,
    required double terminalLongitude,
    String? terminalAddress,
  }) =>
      throw UnimplementedError(
        'MockRulesEngineBackend.evaluateShortHaul — Phase 2',
      );

  @override
  Future<Result<RawJson>> getTaxonomy() =>
      throw UnimplementedError('MockRulesEngineBackend.getTaxonomy — Phase 2');
}

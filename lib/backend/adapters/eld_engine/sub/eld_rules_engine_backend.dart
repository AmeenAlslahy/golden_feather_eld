// ignore_for_file: unused_field, unused_import

import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/result/result.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/rules_engine_backend.dart';
import '../../../http/api_client.dart';

/// ELD Engine implementation of [RulesEngineBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldRulesEngineBackend implements RulesEngineBackend {
  final ApiClient _apiClient;

  const EldRulesEngineBackend(this._apiClient);

  @override
  Future<Result<RawJson>> getCatalog() =>
      throw UnimplementedError('EldRulesEngineBackend.getCatalog — Phase 2');

  @override
  Future<Result<RawJson>> getRuleById(RuleId ruleId) =>
      throw UnimplementedError('EldRulesEngineBackend.getRuleById — Phase 2');

  @override
  Future<Result<RawJson>> getRuleSetVersions(String ruleSetId) =>
      throw UnimplementedError('EldRulesEngineBackend.getRuleSetVersions — Phase 2');

  @override
  Future<Result<RawJson>> getRegulations() =>
      throw UnimplementedError('EldRulesEngineBackend.getRegulations — Phase 2');

  @override
  Future<Result<RawJson>> evaluateShortHaul({
    required DriverId driverId,
    required double currentLatitude,
    required double currentLongitude,
    required double terminalLatitude,
    required double terminalLongitude,
    String? terminalAddress,
  }) =>
      throw UnimplementedError('EldRulesEngineBackend.evaluateShortHaul — Phase 2');

  @override
  Future<Result<RawJson>> getTaxonomy() =>
      throw UnimplementedError('EldRulesEngineBackend.getTaxonomy — Phase 2');
}

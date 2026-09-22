import '../../core/domain/shared/value_objects.dart';
import '../../core/result/result.dart';
import 'raw_json.dart';

abstract interface class RulesEngineBackend {
  /// GET /eld/rules
  Future<Result<RawJson>> getCatalog();

  /// GET /eld/rules/{ruleId}
  Future<Result<RawJson>> getRuleById(RuleId ruleId);

  /// GET /eld/rules/{ruleSetId}/versions
  Future<Result<RawJson>> getRuleSetVersions(String ruleSetId);

  /// GET /eld/rules/regulations
  Future<Result<RawJson>> getRegulations();

  /// POST /eld/rules/short-haul/evaluate
  Future<Result<RawJson>> evaluateShortHaul({
    required DriverId driverId,
    required double currentLatitude,
    required double currentLongitude,
    required double terminalLatitude,
    required double terminalLongitude,
    String? terminalAddress,
  });

  /// GET /eld/rules/taxonomy
  Future<Result<RawJson>> getTaxonomy();
}

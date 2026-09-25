import '../../core/result/result.dart';
import '../../domain/shared/value_objects.dart';
import 'raw_json.dart';

abstract interface class DriverRulesBackend {
  /// POST /eld/drivers/{driverId}/hos/adverse-conditions
  Future<Result<void>> toggleAdverseConditions({
    required DriverId driverId,
    required bool enabled,
    required String reason,
  });

  /// POST /eld/drivers/{driverId}/hos/wellsite-waiting
  Future<Result<void>> logWellsiteWaiting({
    required DriverId driverId,
    required String wellSiteIdentifier,
    required String wellSiteLocation,
    required DateTime startTime,
    required DateTime endTime,
    String? remarks,
  });

  /// PUT /eld/drivers/{driverId}/rules
  Future<Result<void>> applyRule({
    required DriverId driverId,
    required RawJson rule,
  });

  /// GET /eld/drivers/{driverId}/rules/applied
  Future<Result<RawJson>> getAppliedRulesHistory(DriverId driverId);

  /// GET /eld/drivers/{driverId}/rules/applied-at
  Future<Result<RawJson>> getAppliedRuleAt({
    required DriverId driverId,
    required DateTime timestamp,
  });

  /// GET /eld/drivers/{driverId}/rules/effective
  Future<Result<RawJson>> getEffectiveRule(DriverId driverId);
}

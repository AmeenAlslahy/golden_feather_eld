import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/driver_rules_backend.dart';
import '../../../contracts/raw_json.dart';

/// In-memory mock for [DriverRulesBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class MockDriverRulesBackend implements DriverRulesBackend {
  const MockDriverRulesBackend();

  @override
  Future<Result<void>> toggleAdverseConditions({
    required DriverId driverId,
    required bool enabled,
    required String reason,
  }) =>
      throw UnimplementedError(
        'MockDriverRulesBackend.toggleAdverseConditions — Phase 2',
      );

  @override
  Future<Result<void>> logWellsiteWaiting({
    required DriverId driverId,
    required String wellSiteIdentifier,
    required String wellSiteLocation,
    required DateTime startTime,
    required DateTime endTime,
    String? remarks,
  }) =>
      throw UnimplementedError(
        'MockDriverRulesBackend.logWellsiteWaiting — Phase 2',
      );

  @override
  Future<Result<void>> applyRule({
    required DriverId driverId,
    required RawJson rule,
  }) =>
      throw UnimplementedError('MockDriverRulesBackend.applyRule — Phase 2');

  @override
  Future<Result<RawJson>> getAppliedRulesHistory(DriverId driverId) =>
      throw UnimplementedError(
        'MockDriverRulesBackend.getAppliedRulesHistory — Phase 2',
      );

  @override
  Future<Result<RawJson>> getAppliedRuleAt({
    required DriverId driverId,
    required DateTime timestamp,
  }) =>
      throw UnimplementedError(
        'MockDriverRulesBackend.getAppliedRuleAt — Phase 2',
      );

  @override
  Future<Result<RawJson>> getEffectiveRule(DriverId driverId) =>
      throw UnimplementedError(
        'MockDriverRulesBackend.getEffectiveRule — Phase 2',
      );
}

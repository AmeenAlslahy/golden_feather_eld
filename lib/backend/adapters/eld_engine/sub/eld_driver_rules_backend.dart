// ignore_for_file: unused_field, unused_import

import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/driver_rules_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';

/// ELD Engine implementation of [DriverRulesBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldDriverRulesBackend implements DriverRulesBackend {
  final ApiClient _apiClient;

  const EldDriverRulesBackend(this._apiClient);

  @override
  Future<Result<void>> toggleAdverseConditions({
    required DriverId driverId,
    required bool enabled,
    required String reason,
  }) =>
      throw UnimplementedError('EldDriverRulesBackend.toggleAdverseConditions — Phase 2');

  @override
  Future<Result<void>> logWellsiteWaiting({
    required DriverId driverId,
    required String wellSiteIdentifier,
    required String wellSiteLocation,
    required DateTime startTime,
    required DateTime endTime,
    String? remarks,
  }) =>
      throw UnimplementedError('EldDriverRulesBackend.logWellsiteWaiting — Phase 2');

  @override
  Future<Result<void>> applyRule({
    required DriverId driverId,
    required RawJson rule,
  }) =>
      throw UnimplementedError('EldDriverRulesBackend.applyRule — Phase 2');

  @override
  Future<Result<RawJson>> getAppliedRulesHistory(DriverId driverId) =>
      throw UnimplementedError('EldDriverRulesBackend.getAppliedRulesHistory — Phase 2');

  @override
  Future<Result<RawJson>> getAppliedRuleAt({
    required DriverId driverId,
    required DateTime timestamp,
  }) =>
      throw UnimplementedError('EldDriverRulesBackend.getAppliedRuleAt — Phase 2');

  @override
  Future<Result<RawJson>> getEffectiveRule(DriverId driverId) =>
      throw UnimplementedError('EldDriverRulesBackend.getEffectiveRule — Phase 2');
}

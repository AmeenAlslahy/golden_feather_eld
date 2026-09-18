// ignore_for_file: unused_field, unused_import

import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/daily_logs_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';

/// ELD Engine implementation of [DailyLogsBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldDailyLogsBackend implements DailyLogsBackend {
  final ApiClient _apiClient;

  const EldDailyLogsBackend(this._apiClient);

  @override
  Future<Result<RawJson>> list({
    DriverId? driverId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? certificationStatus,
    int? ruleId,
    bool? requiresAction,
    int limit = 50,
    int offset = 0,
  }) =>
      throw UnimplementedError('EldDailyLogsBackend.list — Phase 2');

  @override
  Future<Result<RawJson>> getById(DailyLogId logId) =>
      throw UnimplementedError('EldDailyLogsBackend.getById — Phase 2');

  @override
  Future<Result<RawJson>> proposeCarrierEdit({
    required DailyLogId logId,
    required RawJson edit,
  }) =>
      throw UnimplementedError('EldDailyLogsBackend.proposeCarrierEdit — Phase 2');

  @override
  Future<Result<void>> respondToCarrierEdit({
    required DailyLogId logId,
    required EditId editId,
    required String action,
    String? driverNotes,
  }) =>
      throw UnimplementedError('EldDailyLogsBackend.respondToCarrierEdit — Phase 2');

  @override
  Future<Result<RawJson>> certify({
    required DailyLogId logId,
    required String signatureCertificateId,
    required bool signatureConfirmation,
    required bool certifiedTrue,
  }) =>
      throw UnimplementedError('EldDailyLogsBackend.certify — Phase 2');

  @override
  Future<Result<void>> reassignDriving({
    required DailyLogId logId,
    required DutyStatusId statusId,
    required DriverId targetCoDriverId,
    required String annotation,
  }) =>
      throw UnimplementedError('EldDailyLogsBackend.reassignDriving — Phase 2');

  @override
  Future<Result<RawJson>> getForm(DailyLogId logId) =>
      throw UnimplementedError('EldDailyLogsBackend.getForm — Phase 2');

  @override
  Future<Result<RawJson>> saveForm({
    required DailyLogId logId,
    required RawJson form,
  }) =>
      throw UnimplementedError('EldDailyLogsBackend.saveForm — Phase 2');

  @override
  Future<Result<RawJson>> getGraphGrid(DailyLogId logId) =>
      throw UnimplementedError('EldDailyLogsBackend.getGraphGrid — Phase 2');

  @override
  Future<Result<void>> lock(DailyLogId logId) =>
      throw UnimplementedError('EldDailyLogsBackend.lock — Phase 2');

  @override
  Future<Result<RawJson>> getReadiness(DailyLogId logId) =>
      throw UnimplementedError('EldDailyLogsBackend.getReadiness — Phase 2');
}

import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/daily_logs_backend.dart';
import '../../../contracts/raw_json.dart';

/// In-memory mock for [DailyLogsBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class MockDailyLogsBackend implements DailyLogsBackend {
  const MockDailyLogsBackend();

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
      throw UnimplementedError('MockDailyLogsBackend.list — Phase 2');

  @override
  Future<Result<RawJson>> getById(DailyLogId logId) =>
      throw UnimplementedError('MockDailyLogsBackend.getById — Phase 2');

  @override
  Future<Result<RawJson>> proposeCarrierEdit({
    required DailyLogId logId,
    required RawJson edit,
  }) =>
      throw UnimplementedError(
        'MockDailyLogsBackend.proposeCarrierEdit — Phase 2',
      );

  @override
  Future<Result<void>> respondToCarrierEdit({
    required DailyLogId logId,
    required EditId editId,
    required String action,
    String? driverNotes,
  }) =>
      throw UnimplementedError(
        'MockDailyLogsBackend.respondToCarrierEdit — Phase 2',
      );

  @override
  Future<Result<RawJson>> certify({
    required DailyLogId logId,
    required String signatureCertificateId,
    required bool signatureConfirmation,
    required bool certifiedTrue,
  }) =>
      throw UnimplementedError('MockDailyLogsBackend.certify — Phase 2');

  @override
  Future<Result<void>> reassignDriving({
    required DailyLogId logId,
    required DutyStatusId statusId,
    required DriverId targetCoDriverId,
    required String annotation,
  }) =>
      throw UnimplementedError(
        'MockDailyLogsBackend.reassignDriving — Phase 2',
      );

  @override
  Future<Result<RawJson>> getForm(DailyLogId logId) =>
      throw UnimplementedError('MockDailyLogsBackend.getForm — Phase 2');

  @override
  Future<Result<RawJson>> saveForm({
    required DailyLogId logId,
    required RawJson form,
  }) =>
      throw UnimplementedError('MockDailyLogsBackend.saveForm — Phase 2');

  @override
  Future<Result<RawJson>> getGraphGrid(DailyLogId logId) =>
      throw UnimplementedError('MockDailyLogsBackend.getGraphGrid — Phase 2');

  @override
  Future<Result<void>> lock(DailyLogId logId) =>
      throw UnimplementedError('MockDailyLogsBackend.lock — Phase 2');

  @override
  Future<Result<RawJson>> getReadiness(DailyLogId logId) =>
      throw UnimplementedError('MockDailyLogsBackend.getReadiness — Phase 2');

  @override
  Future<Result<List<dynamic>>> getLegacyDutyStatusLogs(
      int driverId, DateTime date) async {
    return ok([]);
  }

  @override
  Future<Result<List<dynamic>>> getLegacySyncLogs(int driverId) async {
    return ok([]);
  }
}

import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/daily_logs_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../eld_engine/models/certify_dto.dart';
import '../../eld_engine/models/readiness_dto.dart';

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
  }) async {
    return ok({
      'data': [
        {
          'id': 1,
          'uniqueId': 'log_1',
          // المفاتيح تطابق DailyLogDto.fromJson (logDate + قيم COMPLETED/CERTIFIED)
          'logDate': '2023-10-25',
          'formattedTotalWorkTime': '6h 26m',
          'today': true,
          'formStatus': 'COMPLETED',
          'certificationStatus': 'CERTIFIED'
        },
        {
          'id': 2,
          'uniqueId': 'log_2',
          'logDate': '2023-10-24',
          'formattedTotalWorkTime': '10h 15m',
          'today': false,
          'formStatus': 'INCOMPLETE',
          'certificationStatus': 'UNCERTIFIED'
        }
      ]
    });
  }

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
  }) async {
    return ok(null);
  }

  @override
  Future<Result<CertifyResponseDto>> certify(CertifyRequestDto request) async {
    return ok(CertifyResponseDto(
      dailyLogId: request.dailyLogId,
      certificationStatus: 'CERTIFIED',
      isCertified: true,
    ));
  }

  @override
  Future<Result<void>> reassignDriving({
    required DailyLogId logId,
    required DutyStatusId statusId,
    required DriverId targetCoDriverId,
    required String annotation,
  }) async {
    return ok(null);
  }

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
  Future<Result<ReadinessDto>> getReadiness(DailyLogId logId) async {
    return ok(ReadinessDto(
      dailyLogId: logId.value,
      driverId: 101,
      driverName: 'Mock Driver',
      logDate: '2026-09-18',
      readinessStatus: 'READY',
      missingRequirements: [],
      legalStatement: 'I hereby certify that my data entries and my record of duty status for this 24-hour period are true and correct.',
      availableActions: ['CERTIFY'],
    ));
  }

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

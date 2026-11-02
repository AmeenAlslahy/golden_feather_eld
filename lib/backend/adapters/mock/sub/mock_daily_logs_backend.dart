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

  static const List<Map<String, dynamic>> _logs = [
    {
      'id': 1,
      'uniqueId': 'log_1',
      // المفاتيح تطابق DailyLogDto.fromJson (logDate + قيم COMPLETED/CERTIFIED)
      'logDate': '2023-10-25',
      'formattedTotalWorkTime': '6h 26m',
      'today': true,
      'formStatus': 'COMPLETED',
      'certificationStatus': 'CERTIFIED',
      'totals': {
        'total': {'seconds': 23160, 'formatted': '06:26:00'},
      },
      'certified': true,
      'logStatus': 'CERTIFIED',
    },
    {
      'id': 2,
      'uniqueId': 'log_2',
      'logDate': '2023-10-24',
      'formattedTotalWorkTime': '10h 15m',
      'today': false,
      'formStatus': 'INCOMPLETE',
      'certificationStatus': 'UNCERTIFIED',
      'totals': {
        'total': {'seconds': 36900, 'formatted': '10:15:00'},
      },
      'certified': false,
      'logStatus': 'DRAFT',
    },
  ];

  @override
  Future<Result<RawJson>> list({
    DriverId? driverId,
    int? deviceId,
    String? status,
    String? formStatus,
    String? certificationStatus,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? logDate,
    int page = 0,
    int size = 20,
    String? sortBy = 'id',
    String? sortDirection = 'ASC',
  }) async {
    final filtered = _logs.where((log) {
      if (logDate != null) {
        final wanted = logDate.toIso8601String().split('T').first;
        if (log['logDate'] != wanted) return false;
      }
      if (certificationStatus != null &&
          '${log['certificationStatus']}'.toUpperCase() !=
              certificationStatus.toUpperCase()) {
        return false;
      }
      return true;
    }).toList();

    final start = page * size;
    final end = (start + size).clamp(0, filtered.length);
    final window = start >= filtered.length
        ? const <Map<String, dynamic>>[]
        : filtered.sublist(start, end);

    return ok(<String, dynamic>{
      'data': window,
      'pagination': {
        'page': page,
        'size': size,
        'totalElements': filtered.length,
        'totalPages': size <= 0 ? 0 : (filtered.length + size - 1) ~/ size,
        'hasNext': end < filtered.length,
        'hasPrevious': page > 0,
      },
    });
  }

  @override
  Future<Result<RawJson>> getSummary({
    DriverId? driverId,
    int? deviceId,
    String? status,
    String? formStatus,
    String? certificationStatus,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? logDate,
    int page = 0,
    int size = 20,
    String? sortBy = 'id',
    String? sortDirection = 'ASC',
  }) async {
    return ok(<String, dynamic>{
      'totalLogs': _logs.length,
      'certified': _logs.where((l) => l['certified'] == true).length,
      'uncertified': _logs.where((l) => l['certified'] != true).length,
      'withViolations': 0,
      'pagination': {
        'page': page,
        'size': size,
        'totalElements': _logs.length,
        'totalPages': size <= 0 ? 0 : (_logs.length + size - 1) ~/ size,
        'hasNext': (page + 1) * size < _logs.length,
        'hasPrevious': page > 0,
      },
    });
  }

  @override
  Future<Result<RawJson>> getById(DailyLogId logId) =>
      throw UnimplementedError('MockDailyLogsBackend.getById — Phase 2');

  @override
  Future<Result<RawJson>> getTeamStatus(DailyLogId logId) async {
    // Live shape 2026-09-25 (no co-driver linked).
    return ok(<String, dynamic>{
      'dailyLogId': logId.value,
      'primaryDriver': {'id': 101, 'name': 'Demo Driver'},
      'teamModeActive': false,
      'hosRecordsIsolated': true,
      'complianceNote': 'HOS records are fully isolated (SRS 5.8 / FMCSA).',
    });
  }

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
  Future<Result<CertifyResponseDto>> certify(
    CertifyRequestDto request, {
    int? expectedOwnerDriverId,
  }) async {
    return ok(
      CertifyResponseDto(
        dailyLogId: request.dailyLogId,
        certificationStatus: 'CERTIFIED',
        isCertified: true,
      ),
    );
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
    int? expectedOwnerDriverId,
  }) => throw UnimplementedError('MockDailyLogsBackend.saveForm — Phase 2');

  @override
  Future<Result<RawJson>> getEvents(DailyLogId logId) async =>
      ok(<String, dynamic>{
        'dailyLogId': logId.value,
        'graphGrid': {
          'totals': {
            'total': {'seconds': 0, 'formatted': '00:00:00'},
          },
          'segments': <dynamic>[],
        },
        'applicableExceptions': <dynamic>[],
        'events': <dynamic>[],
      });

  @override
  Future<Result<RawJson>> getEventDetails(
    DailyLogId logId,
    DutyStatusId eventId,
  ) async => ok(<String, dynamic>{
    'id': eventId.value,
    'logId': logId.value,
    'status': 'ON_DUTY',
    'editable': true,
  });

  @override
  Future<Result<RawJson>> updateEvent({
    required DailyLogId logId,
    required DutyStatusId eventId,
    required RawJson event,
    int? expectedOwnerDriverId,
  }) async => ok(<String, dynamic>{
    'id': eventId.value,
    'logId': logId.value,
    ...event,
  });

  @override
  Future<Result<RawJson>> getEventsOptions(DailyLogId logId) async =>
      ok(<String, dynamic>{
        'statuses': ['OFF_DUTY', 'SLEEPER_BERTH', 'DRIVING', 'ON_DUTY'],
        'specialCategories': <dynamic>[],
        'editWindowDays': 14,
      });

  @override
  Future<Result<RawJson>> getFormOptions(DailyLogId logId) async =>
      ok(<String, dynamic>{'vehicles': <dynamic>[], 'coDrivers': <dynamic>[]});

  @override
  Future<Result<void>> lock(DailyLogId logId) =>
      throw UnimplementedError('MockDailyLogsBackend.lock — Phase 2');

  @override
  Future<Result<ReadinessDto>> getReadiness(DailyLogId logId) async {
    return ok(
      ReadinessDto(
        dailyLogId: logId.value,
        driverId: 101,
        driverName: 'Mock Driver',
        logDate: '2026-09-18',
        readinessStatus: 'READY',
        missingRequirements: [],
        legalStatement:
            'I hereby certify that my data entries and my record of duty status for this 24-hour period are true and correct.',
        availableActions: ['CERTIFY'],
      ),
    );
  }

  @override
  Future<Result<CertifyStateDto>> getCertifyState(DailyLogId logId) async {
    return ok(
      CertifyStateDto(
        dailyLogId: logId.value,
        logDate: '2026-09-18',
        statementText:
            'I hereby certify that my data entries and my record of duty status for this 24-hour period are true and correct.',
        ruleReference: '49 CFR 395.30',
        hasSignature: false,
        certificationStatus: 'UNCERTIFIED',
        certified: false,
        canCertify: true,
        validationCodes: const [],
      ),
    );
  }
}

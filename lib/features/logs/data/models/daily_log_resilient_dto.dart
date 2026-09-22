/// Resilient DTO — يتحمّل أي تغيير في أسماء حقول الباك-إند دون كسر التطبيق.
///
/// **المبدأ:** اقرأ كل حقل عبر aliases + قيم افتراضية + تحويل آمن.
/// **الفائدة:** `driver_id`, `driverId`, `driver[id]`, `userId` كلها تعمل.
library;

import '../../../../core/api/resilient_mapper.dart';
import '../../../../core/domain/shared/value_objects.dart';
import '../../domain/entities/daily_log.dart';
import 'log_model.dart';

/// DTO مرن لسجل يومي — مثال يُحتذى به لكل DTOs الجديدة.
class DailyLogResilientDto extends ResilientDto {
  final int id;
  final String uniqueId;
  final String logDate;
  final String formattedTotalWorkTime;
  final int totalDurationMinutes;
  final String formStatus;
  final String certificationStatus;
  final bool today;
  final List<Map<String, dynamic>> events;
  final bool requiresAction;
  @override
  final Map<String, dynamic> unknownFields;

  const DailyLogResilientDto({
    required this.id,
    required this.uniqueId,
    required this.logDate,
    required this.formattedTotalWorkTime,
    required this.totalDurationMinutes,
    required this.formStatus,
    required this.certificationStatus,
    required this.today,
    this.events = const [],
    this.requiresAction = false,
    this.unknownFields = const {},
  });

  /// مصنع مرن — لا ينكسر عند إعادة تسمية حقول.
  factory DailyLogResilientDto.fromJson(Map<String, dynamic> json) {
    final f = ResilientField(json);
    // التقط الحقول غير المعروفة للتدقيق
    const known = {'id', 'logId', 'dailyLogId', 'uniqueId', 'uid', 'logDate', 'date', 'formattedTotalWorkTime', 'totalWorkTime', 'totalDurationMinutes', 'duration', 'totalMinutes', 'formStatus', 'status', 'certificationStatus', 'certStatus', 'certified', 'today', 'isToday', 'events', 'dutyEvents', 'requiresAction', 'needsAction'};
    final unknown = {for (final k in json.keys) if (!known.contains(k)) k: json[k]};

    return DailyLogResilientDto(
      id: f.get<int>(['id', 'logId', 'dailyLogId'], fallback: 0)!,
      uniqueId: f.get<String>(['uniqueId', 'uid', 'unique_id'], fallback: '')!,
      logDate: f.get<String>(['logDate', 'date', 'log_date'], fallback: DateTime.now().toIso8601String())!,
      formattedTotalWorkTime: f.get<String>(['formattedTotalWorkTime', 'totalWorkTime', 'formatted_total_work_time'], fallback: '')!,
      totalDurationMinutes: f.get<int>(['totalDurationMinutes', 'duration', 'totalMinutes', 'total_duration_minutes'], fallback: 0)!,
      formStatus: ApiVersionTolerance.normalizeStatus(f.get<String>(['formStatus', 'status', 'form_status']) ?? 'UNKNOWN', fallback: 'UNKNOWN'),
      certificationStatus: ApiVersionTolerance.normalizeStatus(f.get<String>(['certificationStatus', 'certStatus', 'cert_status', 'certification_status']) ?? 'UNKNOWN', fallback: 'UNKNOWN'),
      today: f.get<bool>(['today', 'isToday', 'is_today'], fallback: false)!,
      events: (f.get<List<dynamic>>(['events', 'dutyEvents', 'duty_events']) ?? []).map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{}).toList(),
      requiresAction: f.get<bool>(['requiresAction', 'needsAction', 'requires_action'], fallback: false)!,
      unknownFields: unknown,
    );
  }

  @override
  bool get isValid => id != 0 && uniqueId.isNotEmpty;

  DailyLog toEntity() {
    final mappedForm = switch (formStatus.toUpperCase()) {
      'COMPLETED' => FormStatus.completed,
      'INCOMPLETE' => FormStatus.incomplete,
      _ => FormStatus.unknown,
    };
    final mappedCert = switch (certificationStatus.toUpperCase()) {
      'CERTIFIED' => CertificationStatus.certified,
      'UNCERTIFIED' => CertificationStatus.uncertified,
      'RE_CERTIFICATION_REQUIRED' => CertificationStatus.reCertificationRequired,
      _ => CertificationStatus.unknown,
    };
    return DailyLog(
      id: DailyLogId(id),
      uniqueId: uniqueId,
      date: DateTime.tryParse(logDate) ?? DateTime.now(),
      formattedTotalWorkTime: formattedTotalWorkTime,
      totalDrivingHours: totalDurationMinutes / 60.0,
      formStatus: mappedForm,
      certificationStatus: mappedCert,
      isFormComplete: mappedForm == FormStatus.completed,
      isCertified: mappedCert == CertificationStatus.certified,
      requiresAction: requiresAction,
      events: events.map((e) => LogEventModel.fromJson(e)).toList(),
    );
  }
}

/// Mapper مرن — يعزل التحويل في مكان واحد.
/// عند تغيير الباك-إند، يُعدّل Mapper واحد فقط.
class DailyLogResilientMapper extends ResilientMapper<DailyLogResilientDto, DailyLog> {
  const DailyLogResilientMapper();
  @override
  DailyLog fromDto(DailyLogResilientDto dto) => dto.toEntity();
  @override
  DailyLogResilientDto toDto(DailyLog domain) => DailyLogResilientDto(
        id: domain.id.value,
        uniqueId: domain.uniqueId,
        logDate: domain.date.toIso8601String(),
        formattedTotalWorkTime: domain.formattedTotalWorkTime,
        totalDurationMinutes: (domain.totalDrivingHours * 60).toInt(),
        formStatus: domain.formStatus.name,
        certificationStatus: domain.certificationStatus.name,
        today: false,
        events: [],
      );
}

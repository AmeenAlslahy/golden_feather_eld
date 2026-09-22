import '../../../../core/domain/shared/value_objects.dart';
import '../../domain/entities/daily_log.dart';
import 'log_model.dart';

class DailyLogDto {
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

  const DailyLogDto({
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
  });

  factory DailyLogDto.fromJson(Map<String, dynamic> json) {
    return DailyLogDto(
      id: json['id'] as int? ?? 0,
      uniqueId: json['uniqueId'] as String? ?? '',
      logDate: json['logDate'] as String? ?? DateTime.now().toIso8601String(),
      formattedTotalWorkTime: json['formattedTotalWorkTime'] as String? ?? '',
      totalDurationMinutes: json['totalDurationMinutes'] as int? ?? 0,
      formStatus: json['formStatus'] as String? ?? 'UNKNOWN',
      certificationStatus: json['certificationStatus'] as String? ?? 'UNKNOWN',
      today: json['today'] as bool? ?? false,
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      requiresAction: json['requiresAction'] as bool? ?? false,
    );
  }

  DailyLog toEntity() {
    FormStatus mappedFormStatus;
    switch (formStatus.toUpperCase()) {
      case 'COMPLETED':
        mappedFormStatus = FormStatus.completed;
        break;
      case 'INCOMPLETE':
        mappedFormStatus = FormStatus.incomplete;
        break;
      default:
        mappedFormStatus = FormStatus.unknown;
    }

    CertificationStatus mappedCertStatus;
    switch (certificationStatus.toUpperCase()) {
      case 'CERTIFIED':
        mappedCertStatus = CertificationStatus.certified;
        break;
      case 'UNCERTIFIED':
        mappedCertStatus = CertificationStatus.uncertified;
        break;
      case 'RE_CERTIFICATION_REQUIRED':
        mappedCertStatus = CertificationStatus.reCertificationRequired;
        break;
      default:
        mappedCertStatus = CertificationStatus.unknown;
    }

    return DailyLog(
      id: DailyLogId(id),
      uniqueId: uniqueId,
      date: DateTime.tryParse(logDate) ?? DateTime.now(),
      formattedTotalWorkTime: formattedTotalWorkTime,
      totalDrivingHours: totalDurationMinutes / 60.0,
      formStatus: mappedFormStatus,
      certificationStatus: mappedCertStatus,
      isFormComplete: mappedFormStatus == FormStatus.completed,
      isCertified: mappedCertStatus == CertificationStatus.certified,
      requiresAction: requiresAction,
      events: events.map((e) => LogEventModel.fromJson(e)).toList(),
    );
  }
}

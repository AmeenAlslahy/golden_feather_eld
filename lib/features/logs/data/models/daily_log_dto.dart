import '../../domain/entities/daily_log.dart';
import '../../../../domain/shared/value_objects.dart';
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

  /// حقول التفاصيل — موجودة في جسم `GET /eld/daily-logs/{id}` وقد تتوافر
  /// في صفوف القائمة؛ null يعني "ليست في هذا الرد" وليست قيمة مزيفة.
  final String? driverName;
  final String? vehicleName;
  final String? vin;
  final String? licensePlate;
  final String? carrierName;
  final String? usdotNumber;
  final String? mainOfficeAddress;
  final String? homeTerminalAddress;
  final List<String> trailers;
  final List<String> shippingDocuments;

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
    this.driverName,
    this.vehicleName,
    this.vin,
    this.licensePlate,
    this.carrierName,
    this.usdotNumber,
    this.mainOfficeAddress,
    this.homeTerminalAddress,
    this.trailers = const [],
    this.shippingDocuments = const [],
  });

  factory DailyLogDto.fromJson(Map<String, dynamic> json) {
    final logDateStr = json['logDate'] as String?;
    if (logDateStr == null || logDateStr.trim().isEmpty) {
      throw const FormatException('Missing or empty logDate in DailyLog payload');
    }

    final driver = json['driver'];
    List<String> stringList(Object? raw) =>
        (raw as List?)?.map((e) => e.toString()).toList() ?? const [];

    return DailyLogDto(
      id: json['id'] as int? ?? 0,
      uniqueId: json['uniqueId'] as String? ?? '',
      logDate: logDateStr,
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
      driverName: driver is Map ? driver['name']?.toString() : null,
      vehicleName: (json['vehicleName'] as String?)?.trim(),
      vin: (json['vin'] as String?)?.trim(),
      licensePlate: (json['licensePlate'] as String?)?.trim(),
      carrierName: (json['carrierName'] as String?)?.trim(),
      usdotNumber: (json['usdotNumber'] as String?)?.trim(),
      mainOfficeAddress: (json['mainOfficeAddress'] as String?)?.trim(),
      homeTerminalAddress: (json['homeTerminalAddress'] as String?)?.trim(),
      trailers: stringList(json['trailers']),
      shippingDocuments: stringList(json['shippingDocuments']),
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
      date: DateTime.tryParse(logDate) ?? (throw FormatException('Invalid logDate format: $logDate')),
      formattedTotalWorkTime: formattedTotalWorkTime,
      totalDrivingHours: totalDurationMinutes / 60.0,
      formStatus: mappedFormStatus,
      certificationStatus: mappedCertStatus,
      isFormComplete: mappedFormStatus == FormStatus.completed,
      isCertified: mappedCertStatus == CertificationStatus.certified,
      requiresAction: requiresAction,
      today: today,
      events: events.map((e) => LogEventModel.fromJson(e)).toList(),
      driverName: driverName,
      vehicleName: vehicleName,
      vin: vin,
      licensePlate: licensePlate,
      carrierName: carrierName,
      usdotNumber: usdotNumber,
      mainOfficeAddress: mainOfficeAddress,
      homeTerminalAddress: homeTerminalAddress,
      trailers: trailers,
      shippingDocuments: shippingDocuments,
    );
  }
}

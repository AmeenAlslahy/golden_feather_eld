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
      throw const FormatException(
        'Missing or empty logDate in DailyLog payload',
      );
    }

    final driver = json['driver'];
    List<String> stringList(Object? raw) =>
        (raw as List?)?.map((e) => e.toString()).toList() ?? const [];

    // شكل الوثيقة: `totals.total.{seconds,formatted}`؛ الحقول المسطّحة
    // القديمة (formattedTotalWorkTime/totalDurationMinutes) تبقى احتياطاً.
    final totals = json['totals'] is Map
        ? Map<String, dynamic>.from(json['totals'] as Map)
        : null;
    final total = totals?['total'] is Map
        ? Map<String, dynamic>.from(totals!['total'] as Map)
        : null;
    final totalSeconds = (total?['seconds'] as num?)?.toInt();
    final formattedFromTotals = total?['formatted']?.toString();

    final formIndicator = json['formIndicator'] is Map
        ? Map<String, dynamic>.from(json['formIndicator'] as Map)
        : null;
    final formIndicatorPositive = formIndicator?['positive'] as bool?;
    final formIndicatorColor = formIndicator?['color']
        ?.toString()
        .toUpperCase();

    var formStatusStr = (json['formStatus'] as String?)?.trim();
    if (formStatusStr == null ||
        formStatusStr.isEmpty ||
        formStatusStr.toUpperCase() == 'UNKNOWN') {
      if (formIndicator?['status'] is String) {
        formStatusStr = formIndicator!['status'].toString();
      } else if (formIndicatorPositive == true ||
          formIndicatorColor == 'GREEN') {
        formStatusStr = 'COMPLETE';
      } else if (formIndicatorPositive == false ||
          formIndicatorColor == 'RED') {
        formStatusStr = 'DRAFT';
      }
    }

    // الاعتماد: `certificationStatus` نصاً؛ وعند غيابه نستنتج من
    // `certified: true` أو من `logStatus` عندما تكون قيمته قيمة اعتماد معروفة.
    var certificationStatusStr = (json['certificationStatus'] as String?)
        ?.trim();
    if (certificationStatusStr == null ||
        certificationStatusStr.isEmpty ||
        certificationStatusStr.toUpperCase() == 'UNKNOWN') {
      final certifiedWire = json['certified'] as bool?;
      final logStatus = (json['logStatus'] as String?)?.trim().toUpperCase();
      if (certifiedWire == true || logStatus == 'CERTIFIED') {
        certificationStatusStr = 'CERTIFIED';
      } else if (logStatus == 'RE_CERTIFICATION_REQUIRED' ||
          logStatus == 'REVOKED' ||
          logStatus == 'NOT_READY' ||
          logStatus == 'READY') {
        certificationStatusStr = logStatus;
      }
    }

    final formattedWorkTime = (json['formattedTotalWorkTime'] as String?)
        ?.trim();

    return DailyLogDto(
      id: json['id'] as int? ?? 0,
      uniqueId: json['uniqueId'] as String? ?? '',
      logDate: logDateStr,
      formattedTotalWorkTime:
          formattedWorkTime != null && formattedWorkTime.isNotEmpty
          ? formattedWorkTime
          : (formattedFromTotals ?? ''),
      totalDurationMinutes:
          json['totalDurationMinutes'] as int? ??
          (totalSeconds != null ? (totalSeconds / 60).round() : 0),
      formStatus: formStatusStr ?? 'UNKNOWN',
      certificationStatus: certificationStatusStr ?? 'UNKNOWN',
      today: json['today'] as bool? ?? false,
      events:
          (json['events'] as List<dynamic>?)
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
    switch (formStatus.trim().toUpperCase()) {
      case 'COMPLETE':
      case 'COMPLETED':
        mappedFormStatus = FormStatus.completed;
        break;
      case 'DRAFT':
      case 'INCOMPLETE':
      case 'INVALID':
        mappedFormStatus = FormStatus.incomplete;
        break;
      case 'PENDING_SYNC':
        mappedFormStatus = FormStatus.pendingSync;
        break;
      case 'SAVED_UNCONFIRMED':
        mappedFormStatus = FormStatus.savedUnconfirmed;
        break;
      case 'SYNC_FAILED':
      case 'SYNC_FAILED_PERMANENTLY':
        mappedFormStatus = FormStatus.syncFailed;
        break;
      default:
        mappedFormStatus = FormStatus.unknown;
    }

    CertificationStatus mappedCertStatus;
    switch (certificationStatus.trim().toUpperCase()) {
      case 'CERTIFIED':
        mappedCertStatus = CertificationStatus.certified;
        break;
      case 'PENDING_SYNC':
        mappedCertStatus = CertificationStatus.pendingSync;
        break;
      case 'SYNC_FAILED':
      case 'SYNC_FAILED_PERMANENTLY':
        mappedCertStatus = CertificationStatus.syncFailed;
        break;
      case 'UNCERTIFIED':
      case 'NOT_READY':
      case 'READY':
        mappedCertStatus = CertificationStatus.uncertified;
        break;
      case 'RE_CERTIFICATION_REQUIRED':
      case 'REVOKED':
        mappedCertStatus = CertificationStatus.reCertificationRequired;
        break;
      default:
        mappedCertStatus = CertificationStatus.unknown;
    }

    return DailyLog(
      id: DailyLogId(id),
      uniqueId: uniqueId,
      date:
          DateTime.tryParse(logDate) ??
          (throw FormatException('Invalid logDate format: $logDate')),
      formattedTotalWorkTime: formattedTotalWorkTime,
      totalDrivingHours: totalDurationMinutes / 60.0,
      formStatus: mappedFormStatus,
      certificationStatus: mappedCertStatus,
      isFormComplete: mappedFormStatus == FormStatus.completed,
      isCertified: mappedCertStatus == CertificationStatus.certified,
      requiresAction: requiresAction,
      today: today,
      events: LogEventModel.parseList(events, source: 'daily-log $id'),
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

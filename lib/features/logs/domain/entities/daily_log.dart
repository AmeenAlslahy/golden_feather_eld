import 'package:equatable/equatable.dart';
import '../../../../domain/shared/value_objects.dart';

enum FormStatus { completed, incomplete, unknown }
enum CertificationStatus { certified, uncertified, reCertificationRequired, unknown }

/// كيان السجل اليومي
class DailyLog extends Equatable {
  final DailyLogId id;
  final String uniqueId;
  final DateTime date;
  final String formattedTotalWorkTime;
  final double totalDrivingHours; // Legacy, keep if needed for older screens
  final FormStatus formStatus;
  final CertificationStatus certificationStatus;
  final bool isFormComplete; // Computed from formStatus or kept for legacy
  final bool isCertified; // Computed from certificationStatus or kept for legacy
  final bool requiresAction;
  final bool today;
  final List<LogEvent> events;

  /// حقول التفاصيل من الخادم (`GET /eld/daily-logs/{id}`) — null عندما
  /// يأتي الكائن من صف قائمة لا يحملها، والشاشة تعرض احتياطيها حينها.
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

  const DailyLog({
    required this.id,
    this.uniqueId = '',
    required this.date,
    this.formattedTotalWorkTime = '',
    required this.totalDrivingHours,
    this.formStatus = FormStatus.unknown,
    this.certificationStatus = CertificationStatus.unknown,
    required this.isFormComplete,
    required this.isCertified,
    this.requiresAction = false,
    this.today = false,
    this.events = const [],
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

  DailyLog copyWith({
    DailyLogId? id,
    String? uniqueId,
    DateTime? date,
    String? formattedTotalWorkTime,
    double? totalDrivingHours,
    FormStatus? formStatus,
    CertificationStatus? certificationStatus,
    bool? isFormComplete,
    bool? isCertified,
    bool? requiresAction,
    bool? today,
    List<LogEvent>? events,
    String? driverName,
    String? vehicleName,
    String? vin,
    String? licensePlate,
    String? carrierName,
    String? usdotNumber,
    String? mainOfficeAddress,
    String? homeTerminalAddress,
    List<String>? trailers,
    List<String>? shippingDocuments,
  }) {
    return DailyLog(
      id: id ?? this.id,
      uniqueId: uniqueId ?? this.uniqueId,
      date: date ?? this.date,
      formattedTotalWorkTime: formattedTotalWorkTime ?? this.formattedTotalWorkTime,
      totalDrivingHours: totalDrivingHours ?? this.totalDrivingHours,
      formStatus: formStatus ?? this.formStatus,
      certificationStatus: certificationStatus ?? this.certificationStatus,
      isFormComplete: isFormComplete ?? this.isFormComplete,
      isCertified: isCertified ?? this.isCertified,
      requiresAction: requiresAction ?? this.requiresAction,
      today: today ?? this.today,
      events: events ?? this.events,
      driverName: driverName ?? this.driverName,
      vehicleName: vehicleName ?? this.vehicleName,
      vin: vin ?? this.vin,
      licensePlate: licensePlate ?? this.licensePlate,
      carrierName: carrierName ?? this.carrierName,
      usdotNumber: usdotNumber ?? this.usdotNumber,
      mainOfficeAddress: mainOfficeAddress ?? this.mainOfficeAddress,
      homeTerminalAddress: homeTerminalAddress ?? this.homeTerminalAddress,
      trailers: trailers ?? this.trailers,
      shippingDocuments: shippingDocuments ?? this.shippingDocuments,
    );
  }

  String get dayName {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    }
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
  }

  String get formattedDate {
    return '$dayName - ${[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][date.month - 1]} ${date.day}${_ordinal(date.day)}';
  }

  String _ordinal(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  @override
  List<Object?> get props => [
        id,
        uniqueId,
        date,
        formattedTotalWorkTime,
        totalDrivingHours,
        formStatus,
        certificationStatus,
        isFormComplete,
        isCertified,
        requiresAction,
        today,
        events,
        driverName,
        vehicleName,
        vin,
        licensePlate,
        carrierName,
        usdotNumber,
        mainOfficeAddress,
        homeTerminalAddress,
        trailers,
        shippingDocuments,
      ];
}

/// كيان حدث في السجل
class LogEvent extends Equatable {
  final String id;
  final String status; // OFF, SB, D, ON
  final DateTime startTime;
  final Duration duration;
  final String location;
  final double? odometer;
  final double? engineHours;
  final bool isExpanded; // للـ UI
  final bool? automatedDriving;
  final bool? editable;

  const LogEvent({
    required this.id,
    required this.status,
    required this.startTime,
    required this.duration,
    required this.location,
    this.odometer,
    this.engineHours,
    this.isExpanded = false,
    this.automatedDriving,
    this.editable,
  });

  String get formattedStartTime {
    final h = startTime.hour.toString().padLeft(2, '0');
    final m = startTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  LogEvent copyWith({
    String? id,
    String? status,
    DateTime? startTime,
    Duration? duration,
    String? location,
    double? odometer,
    double? engineHours,
    bool? isExpanded,
    bool? automatedDriving,
    bool? editable,
  }) {
    return LogEvent(
      id: id ?? this.id,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      location: location ?? this.location,
      odometer: odometer ?? this.odometer,
      engineHours: engineHours ?? this.engineHours,
      isExpanded: isExpanded ?? this.isExpanded,
      automatedDriving: automatedDriving ?? this.automatedDriving,
      editable: editable ?? this.editable,
    );
  }

  @override
  List<Object?> get props =>
      [id, status, startTime, duration, location, isExpanded];
}

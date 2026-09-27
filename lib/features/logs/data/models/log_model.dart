import '../../domain/entities/daily_log.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';

class LogEventModel extends LogEvent {
  const LogEventModel({
    required super.id,
    required super.status,
    required super.statusArabic,
    required super.startTime,
    required super.duration,
    required super.location,
    super.odometer,
    super.engineHours,
    super.isExpanded,
    super.automatedDriving,
    super.editable,
  });

  /// Parses either the official `GraphGridEvent` wire shape
  /// (`GET /eld/daily-logs/{id}/graph-grid`: `status` = `DRIVING`/`ON_DUTY`/…,
  /// `durationMinutes`, `odometerKm`, `origin`, `editable`) or the compact
  /// local shape written by [toJson] (`status` = `D`/`ON`/…, `duration` in
  /// seconds, `odometer` in miles).
  factory LogEventModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString() ?? 'OFF';
    final code = DutyStatusCode.fromShortCode(rawStatus) ??
        DutyStatusCode.fromWire(rawStatus);

    final startTimeStr =
        json['startTime']?.toString() ?? json['time']?.toString();

    final Duration duration;
    if (json['durationMinutes'] != null) {
      duration = Duration(
          minutes: int.tryParse(json['durationMinutes'].toString()) ?? 0);
    } else {
      duration =
          Duration(seconds: int.tryParse(json['duration']?.toString() ?? '') ?? 0);
    }

    // Odometer is displayed in miles; the server reports kilometres.
    double? odometer;
    if (json['odometerKm'] != null) {
      final km = double.tryParse(json['odometerKm'].toString());
      odometer = km == null ? null : km * _kmToMiles;
    } else if (json['odometer'] != null) {
      odometer = double.tryParse(json['odometer'].toString());
    }

    final origin = json['origin']?.toString().toUpperCase();
    final bool? automatedDriving = json['automatedDriving'] is bool
        ? json['automatedDriving'] as bool
        : origin?.startsWith('AUTO');

    final location = json['location']?.toString() ??
        json['locationText']?.toString() ??
        'Unknown Location';

    return LogEventModel(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      status: code.shortCode,
      statusArabic: _arabicName(code),
      startTime: startTimeStr != null
          ? DateTime.parse(startTimeStr).toLocal()
          : DateTime.now(),
      duration: duration,
      location: location,
      odometer: odometer,
      engineHours: json['engineHours'] != null
          ? double.tryParse(json['engineHours'].toString())
          : null,
      automatedDriving: automatedDriving,
      editable: json['editable'] is bool ? json['editable'] as bool : null,
    );
  }

  static const double _kmToMiles = 0.621371;

  static String _arabicName(DutyStatusCode code) => switch (code) {
        DutyStatusCode.offDuty => DutyStatus.offDuty.arabicName,
        DutyStatusCode.sleeperBerth => DutyStatus.sleeperBerth.arabicName,
        DutyStatusCode.driving => DutyStatus.driving.arabicName,
        DutyStatusCode.onDutyNotDriving =>
          DutyStatus.onDutyNotDriving.arabicName,
        DutyStatusCode.personalConveyance => DutyStatus.personalUse.arabicName,
        DutyStatusCode.yardMove => 'حركة داخل الساحة',
      };

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'startTime': startTime.toIso8601String(),
      'duration': duration.inSeconds,
      'location': location,
      'odometer': odometer,
      'engineHours': engineHours,
    };
  }

  factory LogEventModel.fromEntity(LogEvent entity) {
    return LogEventModel(
      id: entity.id,
      status: entity.status,
      statusArabic: entity.statusArabic,
      startTime: entity.startTime,
      duration: entity.duration,
      location: entity.location,
      odometer: entity.odometer,
      engineHours: entity.engineHours,
      isExpanded: entity.isExpanded,
      automatedDriving: entity.automatedDriving,
      editable: entity.editable,
    );
  }
}

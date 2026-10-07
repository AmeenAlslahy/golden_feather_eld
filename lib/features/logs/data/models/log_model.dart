import '../../domain/entities/daily_log.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import '../../../../core/utils/logger.dart';

class LogEventModel extends LogEvent {
  const LogEventModel({
    required super.id,
    required super.status,
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
  ///
  /// Throws [FormatException] when `id` or `startTime` is missing: an ELD
  /// record is never given an invented identity or an invented time.
  factory LogEventModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) {
      throw const FormatException('LogEvent without id');
    }
    final startTimeStr =
        json['startTime']?.toString() ?? json['time']?.toString();
    if (startTimeStr == null || startTimeStr.isEmpty) {
      throw FormatException('LogEvent $id without startTime');
    }

    final rawStatus = json['status']?.toString() ?? 'OFF';
    final code = DutyStatusCode.fromShortCode(rawStatus) ??
        DutyStatusCode.fromWire(rawStatus);

    final Duration duration;
    if (json['durationMinutes'] != null) {
      duration = Duration(
          minutes: int.tryParse(json['durationMinutes'].toString()) ?? 0);
    } else if (json['durationSeconds'] != null) {
      // DutyEventDto (استجابة PUT التعديل) يقدم المدة بالثواني.
      duration = Duration(
          seconds: int.tryParse(json['durationSeconds'].toString()) ?? 0);
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
      id: id,
      status: code.shortCode,
      startTime: DateTime.parse(startTimeStr).toLocal(),
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

  /// Parses a list of events, skipping (and logging) any malformed entry so a
  /// single bad record never hides the rest of the driver's day.
  static List<LogEventModel> parseList(
    Iterable<Map<String, dynamic>> raw, {
    required String source,
  }) {
    final events = <LogEventModel>[];
    for (final json in raw) {
      try {
        events.add(LogEventModel.fromJson(json));
      } on FormatException catch (e, st) {
        AppLogger.warning('LogEventModel.parseList($source): skipped', e, st);
      }
    }
    return events;
  }

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

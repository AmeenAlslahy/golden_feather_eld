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
    super.originalLatitude,
    super.originalLongitude,
    super.startedOnPreviousDay,
    super.syncStatus,
  });

  /// Parses the unified event wire shape (`GET /eld/daily-logs/{id}/events`:
  /// `{ id, status: DRIVING/…, startedOnPreviousDay,
  ///    timeRange: { startTime, endTime, durationSeconds, … }, editable }`),
  /// the legacy `GraphGridEvent` shape (`status` = `DRIVING`/`ON_DUTY`/…,
  /// `startTime`, `durationMinutes`, `odometerKm`, `origin`, `editable`) or
  /// the compact local shape written by [toJson] (`status` = `D`/`ON`/…,
  /// `duration` in seconds, `odometer` in miles).
  ///
  /// Throws [FormatException] when `id` or `startTime` is missing: an ELD
  /// record is never given an invented identity or an invented time.
  factory LogEventModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) {
      throw const FormatException('LogEvent without id');
    }
    final timeRange = json['timeRange'] is Map
        ? Map<String, dynamic>.from(json['timeRange'] as Map)
        : null;
    final startTimeStr =
        timeRange?['startTime']?.toString() ??
        json['startTime']?.toString() ??
        json['time']?.toString();
    if (startTimeStr == null || startTimeStr.isEmpty) {
      throw FormatException('LogEvent $id without startTime');
    }

    final rawStatus = json['status']?.toString() ?? 'OFF';
    final code =
        DutyStatusCode.fromShortCode(rawStatus) ??
        DutyStatusCode.fromWire(rawStatus);

    final Duration duration;
    if (timeRange?['durationSeconds'] != null) {
      duration = Duration(
        seconds: int.tryParse(timeRange!['durationSeconds'].toString()) ?? 0,
      );
    } else if (json['durationMinutes'] != null) {
      duration = Duration(
        minutes: int.tryParse(json['durationMinutes'].toString()) ?? 0,
      );
    } else if (json['durationSeconds'] != null) {
      // DutyEventDto (استجابة PUT التعديل) يقدم المدة بالثواني.
      duration = Duration(
        seconds: int.tryParse(json['durationSeconds'].toString()) ?? 0,
      );
    } else {
      duration = Duration(
        seconds: int.tryParse(json['duration']?.toString() ?? '') ?? 0,
      );
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

    // `location` قد يكون كائناً (`{description, latitude, …}`) في عقد
    // تفاصيل/تعديل الحدث، أو نصاً في العقد المضغوط.
    final rawLocation = json['location'];
    String? location;
    double? originalLatitude;
    double? originalLongitude;
    if (rawLocation is Map) {
      location = rawLocation['description']?.toString();
      if (rawLocation['latitude'] != null) {
        originalLatitude = double.tryParse(rawLocation['latitude'].toString());
      }
      if (rawLocation['longitude'] != null) {
        originalLongitude = double.tryParse(rawLocation['longitude'].toString());
      }
    } else if (rawLocation != null) {
      location = rawLocation.toString();
    }
    location ??= json['locationText']?.toString();

    if (originalLatitude == null) {
      final rawLat = json['latitude'] ?? json['originalLatitude'];
      if (rawLat != null) {
        originalLatitude = double.tryParse(rawLat.toString());
      }
    }
    if (originalLongitude == null) {
      final rawLng = json['longitude'] ?? json['originalLongitude'];
      if (rawLng != null) {
        originalLongitude = double.tryParse(rawLng.toString());
      }
    }

    return LogEventModel(
      id: id,
      status: code.shortCode,
      startTime: DateTime.parse(startTimeStr).toLocal(),
      duration: duration,
      location: location ?? 'Unknown Location',
      odometer: odometer,
      engineHours: json['engineHours'] != null
          ? double.tryParse(json['engineHours'].toString())
          : null,
      automatedDriving: automatedDriving,
      editable: json['editable'] is bool ? json['editable'] as bool : null,
      startedOnPreviousDay: json['startedOnPreviousDay'] == true,
      syncStatus: parseSyncStatus(json['syncStatus']),
      originalLatitude: originalLatitude,
      originalLongitude: originalLongitude,
    );
  }

  static const double _kmToMiles = 0.621371;

  /// حالة المزامنة كما تُحفظ في الكاش. `null` للحدث المؤكد كي لا تتضخم
  /// لقطة الخادم بحقل محلي.
  static String? syncStatusToWire(EventSyncStatus status) {
    return switch (status) {
      EventSyncStatus.none => null,
      EventSyncStatus.pendingSync => 'PENDING_SYNC',
      EventSyncStatus.syncFailed => 'SYNC_FAILED',
    };
  }

  static EventSyncStatus parseSyncStatus(Object? raw) {
    final value = raw?.toString().trim().toUpperCase();
    return switch (value) {
      'PENDING_SYNC' ||
      'PENDINGSYNC' ||
      'PENDING' => EventSyncStatus.pendingSync,
      'SYNC_FAILED' || 'SYNCFAILED' || 'FAILED' => EventSyncStatus.syncFailed,
      _ => EventSyncStatus.none,
    };
  }

  /// يدمج استجابة/نسخة جديدة مع نسخة مخزّنة: الحقول الغائبة تبقى، والقيم
  /// غير الفارغة تتغلب، والخرائط المتداخلة تُدمج بدل استبدالها.
  ///
  /// هذا مهم لاستجابة `PUT` التي قد تعيد `location` بلا `description` أو
  /// تحذف حقولاً لم تتغير؛ بلا الدمج يصبح الموقع `Unknown Location`.
  static Map<String, dynamic> mergeJson(
    Map<String, dynamic> existing,
    Map<String, dynamic> incoming,
  ) {
    final merged = <String, dynamic>{...existing};
    for (final entry in incoming.entries) {
      final value = entry.value;
      if (value == null) continue;
      final current = merged[entry.key];
      if (current is Map && value is Map) {
        merged[entry.key] = mergeJson(
          Map<String, dynamic>.from(current),
          Map<String, dynamic>.from(value),
        );
      } else {
        merged[entry.key] = value;
      }
    }

    // إذا جاءت النسخة الجديدة بالشكل المحلي (`startTime` أعلى المستوى) فلا
    // نترك `timeRange` قديماً من لقطة سابقة يتغلب في [fromJson].
    if (!incoming.containsKey('timeRange') &&
        (incoming.containsKey('startTime') ||
            incoming.containsKey('duration') ||
            incoming.containsKey('durationSeconds'))) {
      merged.remove('timeRange');
    }
    return merged;
  }

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
    final syncStatusWire = syncStatusToWire(syncStatus);
    return {
      'id': id,
      'status': status,
      'startTime': startTime.toIso8601String(),
      'duration': duration.inSeconds,
      'location': location,
      'odometer': odometer,
      'engineHours': engineHours,
      'editable': editable,
      'automatedDriving': automatedDriving,
      'startedOnPreviousDay': startedOnPreviousDay,
      if (syncStatusWire != null) 'syncStatus': syncStatusWire,
      if (originalLatitude != null) 'originalLatitude': originalLatitude,
      if (originalLongitude != null) 'originalLongitude': originalLongitude,
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
      startedOnPreviousDay: entity.startedOnPreviousDay,
      syncStatus: entity.syncStatus,
      originalLatitude: entity.originalLatitude,
      originalLongitude: entity.originalLongitude,
    );
  }
}

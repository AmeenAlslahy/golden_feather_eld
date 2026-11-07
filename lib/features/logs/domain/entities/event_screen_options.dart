import 'package:equatable/equatable.dart';
import '../../../../domain/duty_status/duty_status_code.dart';

/// حالة خدمة مسموح بها في شاشة تعديل الحدث.
class EventOptionStatus extends Equatable {
  final String code;
  final String? baseStatus;

  const EventOptionStatus({
    required this.code,
    this.baseStatus,
  });

  factory EventOptionStatus.fromJson(Map<String, dynamic> json) {
    return EventOptionStatus(
      code: json['code']?.toString() ?? '',
      baseStatus: json['baseStatus']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    if (baseStatus != null) 'baseStatus': baseStatus,
  };

  /// مطابقة الكود مع كود حالة الخدمة القياسي [DutyStatusCode].
  DutyStatusCode? get dutyStatusCode => DutyStatusCode.tryFromAny(code);

  @override
  List<Object?> get props => [code, baseStatus];
}

/// مركبة متاحة للاختيار في شاشة تعديل الحدث.
class EventOptionVehicle extends Equatable {
  final int id;
  final String identifier;

  const EventOptionVehicle({
    required this.id,
    required this.identifier,
  });

  factory EventOptionVehicle.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final parsedId =
        rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;
    return EventOptionVehicle(
      id: parsedId,
      identifier: json['identifier']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'identifier': identifier,
  };

  @override
  List<Object?> get props => [id, identifier];
}

/// خيارات ومراجع شاشة تعديل الأحداث المسترجعة من
/// `GET /eld/daily-logs/{id}/events/options`.
class EventScreenOptions extends Equatable {
  final List<EventOptionStatus> statuses;
  final List<EventOptionVehicle> vehicles;
  final List<String> locationSources;

  const EventScreenOptions({
    this.statuses = const [],
    this.vehicles = const [],
    this.locationSources = const [],
  });

  factory EventScreenOptions.fromJson(Map<String, dynamic> json) {
    final rawStatuses = json['statuses'];
    final List<EventOptionStatus> parsedStatuses;
    if (rawStatuses is List) {
      parsedStatuses = rawStatuses
          .map((s) {
            if (s is Map<String, dynamic>) {
              return EventOptionStatus.fromJson(s);
            } else if (s is Map) {
              return EventOptionStatus.fromJson(
                Map<String, dynamic>.from(s),
              );
            } else if (s is String) {
              return EventOptionStatus(code: s);
            }
            return EventOptionStatus(code: s?.toString() ?? '');
          })
          .where((s) => s.code.isNotEmpty)
          .toList();
    } else {
      parsedStatuses = const [];
    }

    final rawVehicles = json['vehicles'];
    final List<EventOptionVehicle> parsedVehicles;
    if (rawVehicles is List) {
      parsedVehicles = rawVehicles
          .map((v) {
            if (v is Map<String, dynamic>) {
              return EventOptionVehicle.fromJson(v);
            } else if (v is Map) {
              return EventOptionVehicle.fromJson(
                Map<String, dynamic>.from(v),
              );
            }
            return EventOptionVehicle(id: 0, identifier: v?.toString() ?? '');
          })
          .where((v) => v.id > 0 || v.identifier.isNotEmpty)
          .toList();
    } else {
      parsedVehicles = const [];
    }

    final rawLocationSources = json['locationSources'];
    final List<String> parsedLocationSources;
    if (rawLocationSources is List) {
      parsedLocationSources = rawLocationSources
          .map((ls) {
            if (ls is Map) {
              return ls['code']?.toString() ?? '';
            }
            return ls?.toString() ?? '';
          })
          .where((code) => code.isNotEmpty)
          .toList();
    } else {
      parsedLocationSources = const [];
    }

    return EventScreenOptions(
      statuses: parsedStatuses,
      vehicles: parsedVehicles,
      locationSources: parsedLocationSources,
    );
  }

  /// الخيارات الافتراضية القياسية المعتمدة قانونياً لـ FMCSA
  /// تُستخدم كـ Fallback آمن عند انقطاع الشبكة أو غياب بيانات الخادم.
  static const EventScreenOptions standardFallback = EventScreenOptions(
    statuses: [
      EventOptionStatus(code: 'OFF_DUTY'),
      EventOptionStatus(code: 'SLEEPER'),
      EventOptionStatus(code: 'DRIVING'),
      EventOptionStatus(code: 'ON_DUTY'),
      EventOptionStatus(code: 'PERSONAL_CONVEYANCE', baseStatus: 'DRIVING'),
      EventOptionStatus(code: 'YARD_MOVE', baseStatus: 'ON_DUTY'),
    ],
    vehicles: [],
    locationSources: ['ELD_AUTO', 'MANUAL'],
  );

  /// فحص ما إذا كانت حالة معينة مسموحاً بها
  bool isStatusAllowed(DutyStatusCode code) {
    if (statuses.isEmpty) return true;
    return statuses.any((s) => s.dutyStatusCode == code);
  }

  @override
  List<Object?> get props => [statuses, vehicles, locationSources];
}

import '../../../../domain/duty_status/duty_status_code.dart';
import '../../../../domain/duty_status/status_dashboard.dart';
import '../../../../domain/duty_status/weekly_recap.dart';
import '../../../../domain/shared/value_objects.dart';
import 'json_primitives.dart';

/// Maps `GET /eld/status`, `POST /eld/status/duty-status`,
/// and `GET /eld/status/recap` JSON to typed domain models.
///
/// **Rule:** All backend chaos lives here. Domain stays clean.
class StatusDashboardMapper {
  const StatusDashboardMapper._();

  // ==========================================================================
  // Public entry points
  // ==========================================================================

  static StatusDashboard fromDashboardJson(Map<String, dynamic> json) {
    return StatusDashboard(
      driver: _parseDriver(json['driver']),
      operationalAlerts: _parseAlerts(json['operationalAlerts']),
      currentDutyStatus: DutyStatusCode.fromWire(
        json['currentDutyStatus'] as String?,
      ),
      remainingCircle: _parseRemainingCircle(json['remainingCircle']),
      hosIndicators: _parseHosIndicators(json['hosIndicators']),
      regulatoryConstraints: _parseConstraints(json['regulatoryConstraints']),
    );
  }

  static WeeklyRecap fromRecapJson(Map<String, dynamic> json) {
    final cycleSummary = json['cycleSummary'] is Map<String, dynamic>
        ? json['cycleSummary'] as Map<String, dynamic>
        : null;

    final ruleWire =
        json['cycleRule'] as String? ?? cycleSummary?['rule'] as String?;
    final cycleRule = CycleRule.fromWire(ruleWire);

    final rawCycleUsed = cycleSummary?['used'] ?? json['cycleUsed'];
    final cycleUsedTime = (rawCycleUsed is num)
        ? RecapTimeValue.present(Duration(minutes: rawCycleUsed.toInt()))
        : RecapTimeValue.fromDynamic(rawCycleUsed);
    final cycleUsed = cycleUsedTime.isPresent
        ? cycleUsedTime.duration!
        : _parseDuration(rawCycleUsed);

    final rawCycleRemaining =
        cycleSummary?['remaining'] ?? json['cycleRemaining'];
    final cycleRemainingTime = (rawCycleRemaining is num)
        ? RecapTimeValue.present(Duration(minutes: rawCycleRemaining.toInt()))
        : RecapTimeValue.fromDynamic(rawCycleRemaining);
    final cycleRemaining = cycleRemainingTime.isPresent
        ? cycleRemainingTime.duration!
        : _parseDuration(rawCycleRemaining);

    final rawAvailableTomorrow =
        cycleSummary?['availableTomorrow'] ?? json['availableTomorrow'];
    final availableTomorrowTime = (rawAvailableTomorrow is num)
        ? RecapTimeValue.present(Duration(minutes: rawAvailableTomorrow.toInt()))
        : RecapTimeValue.fromDynamic(rawAvailableTomorrow);
    final availableTomorrow = availableTomorrowTime.isPresent
        ? availableTomorrowTime.duration!
        : _parseDuration(rawAvailableTomorrow);

    final rawDays = json['dailyRecap'] ?? json['days'];

    return WeeklyRecap(
      cycleRule: cycleRule,
      cycleUsed: cycleUsed,
      cycleRemaining: cycleRemaining,
      availableTomorrow: availableTomorrow,
      days: _parseRecapDays(rawDays),
      cycleUsedTime: cycleUsedTime,
      cycleRemainingTime: cycleRemainingTime,
      availableTomorrowTime: availableTomorrowTime,
    );
  }

  // ==========================================================================
  // Nested parsers
  // ==========================================================================

  static DriverRef _parseDriver(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return const DriverRef(id: DriverId(0), name: '', displayText: '');
    }
    return DriverRef(
      id: DriverId(JsonPrimitives.asInt(raw['id'])),
      name: JsonPrimitives.asString(raw['name']),
      displayText: JsonPrimitives.asString(raw['displayText']),
    );
  }

  static OperationalAlerts _parseAlerts(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return const OperationalAlerts(
        toolIcon: false,
        warningTriangleIcon: false,
        connectionStatus: ConnectionStatus.ok,
      );
    }
    return OperationalAlerts(
      toolIcon: JsonPrimitives.asBool(raw['toolIcon']),
      warningTriangleIcon: JsonPrimitives.asBool(raw['warningTriangleIcon']),
      connectionStatus: raw['connectionStatus'] != null
          ? ConnectionStatus.fromWire(raw['connectionStatus'] as String?)
          : ConnectionStatus.ok,
    );
  }

  static RemainingCircle _parseRemainingCircle(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return const RemainingCircle(
        remaining: Duration.zero,
        label: 'Remaining',
        progress: 0.0,
      );
    }
    final rawTime = raw['time'] ?? raw['remaining'] ?? raw['seconds'];
    Duration remaining = Duration.zero;
    if (raw['seconds'] is num) {
      remaining = Duration(seconds: (raw['seconds'] as num).toInt());
    } else if (rawTime != null) {
      remaining = _parseDuration(rawTime);
    }

    return RemainingCircle(
      remaining: remaining,
      label: JsonPrimitives.asString(
        raw['title'] ?? raw['label'],
        fallback: 'Remaining',
      ),
      progress: JsonPrimitives.asDouble(raw['progress']).clamp(0.0, 1.0),
    );
  }

  static HosIndicators _parseHosIndicators(Object? raw) {
    if (raw is! Map<String, dynamic>) return _emptyIndicators();
    return HosIndicators(
      drive: _parseIndicator(
        raw['drive'],
        fallbackLabel: 'DRIVE',
        fallbackType: IndicatorType.remaining,
      ),
      shift: _parseIndicator(
        raw['shift'],
        fallbackLabel: 'SHIFT',
        fallbackType: IndicatorType.remaining,
      ),
      breakTime: _parseIndicator(
        raw['breakTime'] ?? raw['break'],
        fallbackLabel: 'BREAK',
        fallbackType: IndicatorType.remaining,
      ),
      cycle: _parseIndicator(
        raw['cycle'],
        fallbackLabel: 'CYCLE',
        fallbackType: IndicatorType.remaining,
      ),
    );
  }

  static HosIndicator _parseIndicator(
    Object? raw, {
    required String fallbackLabel,
    IndicatorType fallbackType = IndicatorType.used,
  }) {
    if (raw is! Map<String, dynamic>) {
      return HosIndicator(
        label: fallbackLabel,
        value: Duration.zero,
        type: fallbackType,
      );
    }

    final rawType = raw['type'] as String?;
    final type = rawType != null
        ? IndicatorType.fromWire(rawType)
        : fallbackType;

    final label = JsonPrimitives.asString(
      raw['title'] ?? raw['label'],
      fallback: fallbackLabel,
    );
    final subtitle = raw['subtitle'] as String?;

    Duration value = Duration.zero;
    if (raw['seconds'] is num) {
      value = Duration(seconds: (raw['seconds'] as num).toInt());
    } else if (raw['value'] != null) {
      value = _parseDuration(raw['value']);
    }

    return HosIndicator(
      label: label,
      subtitle: subtitle,
      value: value,
      type: type,
    );
  }

  static RegulatoryConstraints _parseConstraints(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return const RegulatoryConstraints(
        ruleSet: CycleRule.unknown,
        limits: [],
      );
    }
    return RegulatoryConstraints(
      ruleSet: CycleRule.fromWire(raw['ruleSet'] as String?),
      limits: _asStringList(raw['limits']),
    );
  }

  static List<RecapDay> _parseRecapDays(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(_parseRecapDay)
        .toList(growable: false);
  }

  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static RecapDay _parseRecapDay(Map<String, dynamic> json) {
    final date = _parseDate(json['date']);

    // 1. dayOfWeek: use server dayOfWeek if provided, otherwise derive from date.
    var dayOfWeek = JsonPrimitives.asString(json['dayOfWeek']);
    if (dayOfWeek.isEmpty) {
      final wd = date.weekday;
      dayOfWeek = (wd >= 1 && wd <= 7) ? _weekdays[wd - 1] : 'Mon';
    }

    // 2. driving: parse as RecapTimeValue.
    // If driving is missing from json, do not fabricate a zero duration.
    final hasDriving = json.containsKey('driving') && json['driving'] != null;
    final rawDriving = json['driving'];
    final drivingTime = (rawDriving is num)
        ? RecapTimeValue.present(Duration(minutes: rawDriving.toInt()))
        : (hasDriving
            ? RecapTimeValue.fromDynamic(rawDriving)
            : RecapTimeValue.missing());
    final legacyDriving = drivingTime.isPresent
        ? drivingTime.duration!
        : _parseDuration(json['driving']);

    // 3. onDuty: parse as RecapTimeValue.
    final hasOnDuty = json.containsKey('onDuty') && json['onDuty'] != null;
    final rawOnDuty = json['onDuty'];
    final onDutyTime = (rawOnDuty is num)
        ? RecapTimeValue.present(Duration(minutes: rawOnDuty.toInt()))
        : (hasOnDuty
            ? RecapTimeValue.fromDynamic(rawOnDuty)
            : RecapTimeValue.missing());
    final legacyOnDuty = onDutyTime.isPresent
        ? onDutyTime.duration!
        : _parseDuration(json['onDuty']);

    // 4. totalWork: parse if explicitly present in JSON.
    // Do NOT assume onDuty == totalWork, do NOT compute driving + onDuty.
    final hasTotalWork =
        json.containsKey('totalWork') && json['totalWork'] != null;
    final rawTotalWork = json['totalWork'];
    final totalWorkTime = (rawTotalWork is num)
        ? RecapTimeValue.present(Duration(minutes: rawTotalWork.toInt()))
        : (hasTotalWork
            ? RecapTimeValue.fromDynamic(rawTotalWork)
            : RecapTimeValue.missing());
    final legacyTotalWork = totalWorkTime.isPresent
        ? totalWorkTime.duration!
        : _parseDuration(json['totalWork']);

    return RecapDay(
      date: date,
      dayOfWeek: dayOfWeek,
      driving: legacyDriving,
      onDuty: legacyOnDuty,
      totalWork: legacyTotalWork,
      drivingTime: drivingTime,
      onDutyTime: onDutyTime,
      totalWorkTime: totalWorkTime,
    );
  }

  // ==========================================================================
  // Primitive parsers
  // ==========================================================================

  static List<String> _asStringList(Object? v) {
    if (v is! List) return const [];
    return v
        .map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime _parseDate(Object? v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  /// Parses `"HH:MM"` or `"HH:MM:SS"` (with optional `-` sign).
  /// Also accepts a numeric value interpreted as **minutes**, or a Map with `seconds`.
  static Duration _parseDuration(Object? v) {
    if (v is Map) {
      final seconds = v['seconds'];
      if (seconds is num) return Duration(seconds: seconds.toInt());
    }
    if (v is num) return Duration(minutes: v.toInt());
    if (v is! String) return Duration.zero;

    final s = v.trim();
    if (s.isEmpty) return Duration.zero;

    final negative = s.startsWith('-');
    final body = negative ? s.substring(1) : s;
    final parts = body.split(':');
    if (parts.length < 2 || parts.length > 3) return Duration.zero;

    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    final seconds = parts.length == 3 ? int.tryParse(parts[2]) : 0;

    if (hours == null || minutes == null || seconds == null) {
      return Duration.zero;
    }

    final duration = Duration(hours: hours, minutes: minutes, seconds: seconds);
    return negative ? -duration : duration;
  }

  static HosIndicators _emptyIndicators() {
    return const HosIndicators(
      drive: HosIndicator(
        label: 'DRIVE',
        value: Duration.zero,
        type: IndicatorType.remaining,
      ),
      shift: HosIndicator(
        label: 'SHIFT',
        value: Duration.zero,
        type: IndicatorType.remaining,
      ),
      breakTime: HosIndicator(
        label: 'BREAK',
        value: Duration.zero,
        type: IndicatorType.remaining,
      ),
      cycle: HosIndicator(
        label: 'CYCLE',
        value: Duration.zero,
        type: IndicatorType.remaining,
      ),
    );
  }
}

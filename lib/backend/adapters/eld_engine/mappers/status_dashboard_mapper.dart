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
      currentDutyStatus:
          DutyStatusCode.fromWire(json['currentDutyStatus'] as String?),
      remainingCircle: _parseRemainingCircle(json['remainingCircle']),
      hosIndicators: _parseHosIndicators(json['hosIndicators']),
      regulatoryConstraints: _parseConstraints(json['regulatoryConstraints']),
    );
  }

  static WeeklyRecap fromRecapJson(Map<String, dynamic> json) {
    return WeeklyRecap(
      cycleRule: CycleRule.fromWire(json['cycleRule'] as String?),
      cycleUsed: _parseDuration(json['cycleUsed']),
      cycleRemaining: _parseDuration(json['cycleRemaining']),
      availableTomorrow: _parseDuration(json['availableTomorrow']),
      days: _parseRecapDays(json['days']),
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
    return RemainingCircle(
      remaining: _parseDuration(raw['time']),
      label: JsonPrimitives.asString(raw['label'], fallback: 'Remaining'),
      progress: JsonPrimitives.asDouble(raw['progress']).clamp(0.0, 1.0),
    );
  }

  static HosIndicators _parseHosIndicators(Object? raw) {
    if (raw is! Map<String, dynamic>) return _emptyIndicators();
    return HosIndicators(
      drive: _parseIndicator(raw['drive'], fallbackLabel: 'DRIVE'),
      shift: _parseIndicator(raw['shift'], fallbackLabel: 'SHIFT'),
      breakTime: _parseIndicator(raw['breakTime'], fallbackLabel: 'BREAK'),
      cycle: _parseIndicator(raw['cycle'], fallbackLabel: 'CYCLE'),
    );
  }

  static HosIndicator _parseIndicator(
    Object? raw, {
    required String fallbackLabel,
  }) {
    if (raw is! Map<String, dynamic>) {
      return HosIndicator(
        label: fallbackLabel,
        value: Duration.zero,
        type: IndicatorType.used,
      );
    }
    return HosIndicator(
      label: JsonPrimitives.asString(raw['label'], fallback: fallbackLabel),
      value: _parseDuration(raw['value']),
      type: IndicatorType.fromWire(raw['type'] as String?),
    );
  }

  static RegulatoryConstraints _parseConstraints(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return const RegulatoryConstraints(ruleSet: CycleRule.unknown, limits: []);
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

  static RecapDay _parseRecapDay(Map<String, dynamic> json) {
    return RecapDay(
      date: _parseDate(json['date']),
      dayOfWeek: JsonPrimitives.asString(json['dayOfWeek']),
      driving: _parseDuration(json['driving']),
      onDuty: _parseDuration(json['onDuty']),
      totalWork: _parseDuration(json['totalWork']),
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
  /// Also accepts a numeric value interpreted as **minutes**.
  static Duration _parseDuration(Object? v) {
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
        type: IndicatorType.used,
      ),
      shift: HosIndicator(
        label: 'SHIFT',
        value: Duration.zero,
        type: IndicatorType.used,
      ),
      breakTime: HosIndicator(
        label: 'BREAK',
        value: Duration.zero,
        type: IndicatorType.remaining,
      ),
      cycle: HosIndicator(
        label: 'CYCLE',
        value: Duration.zero,
        type: IndicatorType.used,
      ),
    );
  }
}

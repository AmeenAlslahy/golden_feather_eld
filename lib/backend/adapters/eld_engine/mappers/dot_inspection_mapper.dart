import '../../../../domain/inspection/dot_inspection.dart';
import '../../../../domain/shared/value_objects.dart';

class DotInspectionMapper {
  const DotInspectionMapper._();

  static DotInspectionScreen fromScreenJson(Map<String, dynamic> json) {
    return DotInspectionScreen(
      screenTitle: _asString(json['screenTitle']),
      guidanceText: _asString(json['guidanceText']),
      handOverDeviceNotice: _asString(json['handOverDeviceNotice']),
      carrierComplianceStatement:
          _asString(json['carrierComplianceStatement']),
      carrierName: _asString(json['carrierName']),
      usdotNumber: _asString(json['usdotNumber']),
      eldIdentifier: _asString(json['eldIdentifier']),
      eldRegistrationId: _asString(json['eldRegistrationId']),
      driverId: DriverId(_asInt(json['driver']?['id'])),
      driverName: _asString(json['driver']?['name']),
      inspectionDate: _asDate(json['inspectionDate']),
      cycleDaysCovered: _asInt(json['cycleDaysCovered']),
      canStartInspection: _asBool(json['canStartInspection'], fallback: true), // absent flag must not lock the driver out
      canSendLogs: _asBool(json['canSendLogs'], fallback: true), // absent flag must not lock the driver out
      canEmailLogs: _asBool(json['canEmailLogs'], fallback: true), // absent flag must not lock the driver out
      canViewInformationPacket: _asBool(json['canViewInformationPacket'], fallback: true), // absent flag must not lock the driver out
      inspectionActive: _asBool(json['inspectionActive']),
      readOnlyMode: _asBool(json['readOnlyMode']),
      activeInspectionId: json['activeInspectionId'] as int?,
      inspectorName: json['inspectorName'] as String?,
    );
  }

  static List<DotInspectionCycleDay> fromCycleJson(List<dynamic> raw) {
    return raw
        .whereType<Map<String, dynamic>>()
        .map(fromCycleDayJson)
        .toList(growable: false);
  }

  static DotInspectionCycleDay fromCycleDayJson(Map<String, dynamic> json) {
    return DotInspectionCycleDay(
      driverId: DriverId(_asInt(json['driver']?['id'])),
      driverName: _asString(json['driver']?['name']),
      logDate: _asDate(json['logDate']),
      displayDate: _asString(json['displayDate']),
      displayLocation: _asString(json['displayLocation']),
      certified: _asBool(json['certified']),
      certifiedAt: _asDateOrNull(json['certifiedAt']),
      eldRegistrationId: _asString(json['eldRegistrationId']),
      eldIdentifier: _asString(json['eldIdentifier']),
      eldProvider: _asString(json['eldProvider']),
      vehicleNumber: _asString(json['vehicleNumber']),
      uniqueId: _asString(json['uniqueId']),
      vin: _asString(json['vin']),
      startOdometerKm: _asDouble(json['startOdometerKm']),
      endOdometerKm: _asDouble(json['endOdometerKm']),
      totalDistanceKm: _asDouble(json['totalDistanceKm']),
      engineHours: _asDouble(json['engineHours']),
      trailers: _asString(json['trailers']),
      shippingDocuments: _asString(json['shippingDocuments']),
      carrierName: _asString(json['carrierName']),
      usdotNumber: _asString(json['usdotNumber']),
      mainOfficeAddress: _asString(json['mainOfficeAddress']),
      homeTerminalAddress: _asString(json['homeTerminalAddress']),
      activeDataDiagnostics: _asStringList(json['activeDataDiagnostics']),
      activeDeviceMalfunctions:
          _asStringList(json['activeDeviceMalfunctions']),
      exemptDriver: _asBool(json['exemptDriver']),
      exemptReason: json['exemptReason'] as String?,
      hasUnidentifiedDriving: _asBool(json['hasUnidentifiedDriving']),
      unidentifiedDrivingCount: _asInt(json['unidentifiedDrivingCount']),
    );
  }

  static DotInspectionLog fromLogJson(Map<String, dynamic> json) {
    return DotInspectionLog(
      driverId: DriverId(_asInt(json['driver']?['id'])),
      driverName: _asString(json['driver']?['name']),
      logDate: _asDate(json['logDate']),
      displayDate: _asString(json['displayDate']),
      displayLocation: _asString(json['displayLocation']),
      certified: _asBool(json['certified']),
      certifiedAt: _asDateOrNull(json['certifiedAt']),
      eldRegistrationId: _asString(json['eldRegistrationId']),
      eldIdentifier: _asString(json['eldIdentifier']),
      eldProvider: _asString(json['eldProvider']),
      vehicleNumber: _asString(json['vehicleNumber']),
      uniqueId: _asString(json['uniqueId']),
      vin: _asString(json['vin']),
      startOdometerKm: _asDouble(json['startOdometerKm']),
      endOdometerKm: _asDouble(json['endOdometerKm']),
      totalDistanceKm: _asDouble(json['totalDistanceKm']),
      engineHours: _asDouble(json['engineHours']),
      trailers: _asString(json['trailers']),
      shippingDocuments: _asString(json['shippingDocuments']),
      carrierName: _asString(json['carrierName']),
      usdotNumber: _asString(json['usdotNumber']),
      mainOfficeAddress: _asString(json['mainOfficeAddress']),
      homeTerminalAddress: _asString(json['homeTerminalAddress']),
      activeDataDiagnostics: _asStringList(json['activeDataDiagnostics']),
      activeDeviceMalfunctions:
          _asStringList(json['activeDeviceMalfunctions']),
      events: _parseEvents(json['events']),
      readOnly: _asBool(json['readOnly']),
      period24HourStartTime: _asLocalTime(json['period24HourStartTime']),
      driverLicenseNumber: _asStringOrNull(json['driver']?['licenseNumber']),
      driverLicenseState: _asStringOrNull(json['driver']?['licenseState']),
      coDriverName: _asStringOrNull(json['coDriver']?['name']),
      coDriverId: json['coDriver']?['id'] is num
          ? (json['coDriver']['id'] as num).toInt()
          : null,
    );
  }

  static String? _asStringOrNull(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// `LocalTime` = `{hour, minute, second, nano}` (or an `HH:mm[:ss]` string).
  static String? _asLocalTime(Object? raw) {
    if (raw is Map) {
      final h = _asInt(raw['hour']);
      final m = _asInt(raw['minute']);
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }
    if (raw is String && raw.length >= 5) return raw.substring(0, 5);
    return null;
  }

  static List<DotInspectionEvent> _parseEvents(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => DotInspectionEvent(
            sequenceNumber: _asInt(e['sequenceNumber']),
            timeEt: _asString(e['timeEt']),
            eventCode: _asString(e['eventCode']),
            eventType: _asString(e['eventType']),
            description: _asString(e['description']),
            location: _asString(e['location']),
            odometer: _asDouble(e['odometer']),
            engineHours: _asDouble(e['engineHours']),
            origin: _asString(e['origin']),
            notes: _asString(e['notes']),
            certificationEvent: _asBool(e['certificationEvent']),
          ),
        )
        .toList(growable: false);
  }

  // ==========================================================================
  // Primitives
  // ==========================================================================

  static String _asString(Object? v, {String fallback = ''}) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  static int _asInt(Object? v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static double _asDouble(Object? v, {double fallback = 0.0}) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static bool _asBool(Object? v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true';
    return fallback;
  }

  static List<String> _asStringList(Object? v) {
    if (v is! List) return const [];
    return v
        .map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime _asDate(Object? v) {
    // التاريخ الناقص يُعلَّم بميلاد Unix (1970) لا بتاريخ وهمي يبدو حقيقياً —
    // عرض 2026-01-01 كان قد يُقدَّم كأنه تاريخ رسمي في شاشة التفتيش.
    return _asDateOrNull(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _asDateOrNull(Object? v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}

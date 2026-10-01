import '../../../../domain/inspection/dot_inspection.dart';
import '../../../../domain/shared/value_objects.dart';
import 'json_primitives.dart';

class DotInspectionMapper {
  const DotInspectionMapper._();

  static DotInspectionScreen fromScreenJson(Map<String, dynamic> json) {
    return DotInspectionScreen(
      screenTitle: JsonPrimitives.asString(json['screenTitle']),
      guidanceText: JsonPrimitives.asString(json['guidanceText']),
      handOverDeviceNotice: JsonPrimitives.asString(json['handOverDeviceNotice']),
      carrierComplianceStatement:
          JsonPrimitives.asString(json['carrierComplianceStatement']),
      carrierName: JsonPrimitives.asString(json['carrierName']),
      usdotNumber: JsonPrimitives.asString(json['usdotNumber']),
      eldIdentifier: JsonPrimitives.asString(json['eldIdentifier']),
      eldRegistrationId: JsonPrimitives.asString(json['eldRegistrationId']),
      driverId: DriverId(JsonPrimitives.asInt(json['driver']?['id'])),
      driverName: JsonPrimitives.asString(json['driver']?['name']),
      inspectionDate: JsonPrimitives.asDate(json['inspectionDate']),
      cycleDaysCovered: JsonPrimitives.asInt(json['cycleDaysCovered']),
      canStartInspection: JsonPrimitives.asBool(json['canStartInspection'], fallback: true), // absent flag must not lock the driver out
      canSendLogs: JsonPrimitives.asBool(json['canSendLogs'], fallback: true), // absent flag must not lock the driver out
      canEmailLogs: JsonPrimitives.asBool(json['canEmailLogs'], fallback: true), // absent flag must not lock the driver out
      canViewInformationPacket: JsonPrimitives.asBool(json['canViewInformationPacket'], fallback: true), // absent flag must not lock the driver out
      inspectionActive: JsonPrimitives.asBool(json['inspectionActive']),
      readOnlyMode: JsonPrimitives.asBool(json['readOnlyMode']),
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
      driverId: DriverId(JsonPrimitives.asInt(json['driver']?['id'])),
      driverName: JsonPrimitives.asString(json['driver']?['name']),
      logDate: JsonPrimitives.asDate(json['logDate']),
      displayDate: JsonPrimitives.asString(json['displayDate']),
      displayLocation: JsonPrimitives.asString(json['displayLocation']),
      certified: JsonPrimitives.asBool(json['certified']),
      certifiedAt: JsonPrimitives.asDateOrNull(json['certifiedAt']),
      eldRegistrationId: JsonPrimitives.asString(json['eldRegistrationId']),
      eldIdentifier: JsonPrimitives.asString(json['eldIdentifier']),
      eldProvider: JsonPrimitives.asString(json['eldProvider']),
      vehicleNumber: JsonPrimitives.asString(json['vehicleNumber']),
      uniqueId: JsonPrimitives.asString(json['uniqueId']),
      vin: JsonPrimitives.asString(json['vin']),
      startOdometerKm: JsonPrimitives.asDouble(json['startOdometerKm']),
      endOdometerKm: JsonPrimitives.asDouble(json['endOdometerKm']),
      totalDistanceKm: JsonPrimitives.asDouble(json['totalDistanceKm']),
      engineHours: JsonPrimitives.asDouble(json['engineHours']),
      trailers: JsonPrimitives.asString(json['trailers']),
      shippingDocuments: JsonPrimitives.asString(json['shippingDocuments']),
      carrierName: JsonPrimitives.asString(json['carrierName']),
      usdotNumber: JsonPrimitives.asString(json['usdotNumber']),
      mainOfficeAddress: JsonPrimitives.asString(json['mainOfficeAddress']),
      homeTerminalAddress: JsonPrimitives.asString(json['homeTerminalAddress']),
      activeDataDiagnostics: JsonPrimitives.asStringList(json['activeDataDiagnostics']),
      activeDeviceMalfunctions:
          JsonPrimitives.asStringList(json['activeDeviceMalfunctions']),
      exemptDriver: JsonPrimitives.asBool(json['exemptDriver']),
      exemptReason: json['exemptReason'] as String?,
      hasUnidentifiedDriving: JsonPrimitives.asBool(json['hasUnidentifiedDriving']),
      unidentifiedDrivingCount: JsonPrimitives.asInt(json['unidentifiedDrivingCount']),
    );
  }

  static DotInspectionLog fromLogJson(Map<String, dynamic> json) {
    return DotInspectionLog(
      driverId: DriverId(JsonPrimitives.asInt(json['driver']?['id'])),
      driverName: JsonPrimitives.asString(json['driver']?['name']),
      logDate: JsonPrimitives.asDate(json['logDate']),
      displayDate: JsonPrimitives.asString(json['displayDate']),
      displayLocation: JsonPrimitives.asString(json['displayLocation']),
      certified: JsonPrimitives.asBool(json['certified']),
      certifiedAt: JsonPrimitives.asDateOrNull(json['certifiedAt']),
      eldRegistrationId: JsonPrimitives.asString(json['eldRegistrationId']),
      eldIdentifier: JsonPrimitives.asString(json['eldIdentifier']),
      eldProvider: JsonPrimitives.asString(json['eldProvider']),
      vehicleNumber: JsonPrimitives.asString(json['vehicleNumber']),
      uniqueId: JsonPrimitives.asString(json['uniqueId']),
      vin: JsonPrimitives.asString(json['vin']),
      startOdometerKm: JsonPrimitives.asDouble(json['startOdometerKm']),
      endOdometerKm: JsonPrimitives.asDouble(json['endOdometerKm']),
      totalDistanceKm: JsonPrimitives.asDouble(json['totalDistanceKm']),
      engineHours: JsonPrimitives.asDouble(json['engineHours']),
      trailers: JsonPrimitives.asString(json['trailers']),
      shippingDocuments: JsonPrimitives.asString(json['shippingDocuments']),
      carrierName: JsonPrimitives.asString(json['carrierName']),
      usdotNumber: JsonPrimitives.asString(json['usdotNumber']),
      mainOfficeAddress: JsonPrimitives.asString(json['mainOfficeAddress']),
      homeTerminalAddress: JsonPrimitives.asString(json['homeTerminalAddress']),
      activeDataDiagnostics: JsonPrimitives.asStringList(json['activeDataDiagnostics']),
      activeDeviceMalfunctions:
          JsonPrimitives.asStringList(json['activeDeviceMalfunctions']),
      events: _parseEvents(json['events']),
      readOnly: JsonPrimitives.asBool(json['readOnly']),
      period24HourStartTime: JsonPrimitives.asLocalTime(json['period24HourStartTime']),
      driverLicenseNumber: JsonPrimitives.asStringOrNull(json['driver']?['licenseNumber']),
      driverLicenseState: JsonPrimitives.asStringOrNull(json['driver']?['licenseState']),
      coDriverName: JsonPrimitives.asStringOrNull(json['coDriver']?['name']),
      coDriverId: json['coDriver']?['id'] is num
          ? (json['coDriver']['id'] as num).toInt()
          : null,
    );
  }


  /// `LocalTime` = `{hour, minute, second, nano}` (or an `HH:mm[:ss]` string).

  static List<DotInspectionEvent> _parseEvents(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => DotInspectionEvent(
            sequenceNumber: JsonPrimitives.asInt(e['sequenceNumber']),
            timeEt: JsonPrimitives.asString(e['timeEt']),
            eventCode: JsonPrimitives.asString(e['eventCode']),
            eventType: JsonPrimitives.asString(e['eventType']),
            description: JsonPrimitives.asString(e['description']),
            location: JsonPrimitives.asString(e['location']),
            odometer: JsonPrimitives.asDouble(e['odometer']),
            engineHours: JsonPrimitives.asDouble(e['engineHours']),
            origin: JsonPrimitives.asString(e['origin']),
            notes: JsonPrimitives.asString(e['notes']),
            certificationEvent: JsonPrimitives.asBool(e['certificationEvent']),
          ),
        )
        .toList(growable: false);
  }

  // ==========================================================================
  // Primitives
  // ==========================================================================







}

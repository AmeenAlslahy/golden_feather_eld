import '../../../../domain/inspection/dot_inspection.dart';
import '../../../../domain/shared/value_objects.dart';
import 'json_primitives.dart';

class DotInspectionMapper {
  const DotInspectionMapper._();

  static DotInspectionScreen fromScreenJson(Map<String, dynamic> json) {
    final carrierObj = json['carrier'] is Map<String, dynamic> ? json['carrier'] as Map<String, dynamic> : null;
    final eldObj = json['eld'] is Map<String, dynamic> ? json['eld'] as Map<String, dynamic> : null;
    final driverObj = json['driver'] is Map<String, dynamic> ? json['driver'] as Map<String, dynamic> : null;

    final isStatusActive = json['status'] is String && (json['status'] as String).toUpperCase() == 'ACTIVE';
    final hasLogs = json['inspectionLogs'] is List && (json['inspectionLogs'] as List).isNotEmpty;
    final cycleDays = hasLogs
        ? (json['inspectionLogs'] as List).length
        : JsonPrimitives.asInt(json['cycleDaysCovered']);

    return DotInspectionScreen(
      screenTitle: JsonPrimitives.asString(json['screenTitle']),
      guidanceText: JsonPrimitives.asString(json['guidanceText']),
      handOverDeviceNotice: JsonPrimitives.asString(
        json['handOverDeviceNotice'],
      ),
      carrierComplianceStatement: JsonPrimitives.asString(
        json['carrierComplianceStatement'],
      ),
      carrierName: JsonPrimitives.asString(carrierObj?['name'] ?? json['carrierName']),
      usdotNumber: JsonPrimitives.asString(carrierObj?['dotNumber'] ?? json['usdotNumber']),
      eldIdentifier: JsonPrimitives.asString(eldObj?['identifier'] ?? json['eldIdentifier']),
      eldRegistrationId: JsonPrimitives.asString(eldObj?['registrationId'] ?? json['eldRegistrationId']),
      driverId: DriverId(JsonPrimitives.asInt(driverObj?['id'])),
      driverName: JsonPrimitives.asString(driverObj?['name']),
      inspectionDate: JsonPrimitives.asDate(json['startedAt'] ?? json['inspectionDate']),
      cycleDaysCovered: cycleDays,
      canStartInspection: JsonPrimitives.asBool(
        json['canStartInspection'],
        fallback: true,
      ), // absent flag must not lock the driver out
      canSendLogs: JsonPrimitives.asBool(
        json['canSendLogs'],
        fallback: true,
      ), // absent flag must not lock the driver out
      canEmailLogs: JsonPrimitives.asBool(
        json['canEmailLogs'],
        fallback: true,
      ), // absent flag must not lock the driver out
      canViewInformationPacket: JsonPrimitives.asBool(
        json['canViewInformationPacket'],
        fallback: true,
      ), // absent flag must not lock the driver out
      inspectionActive: isStatusActive || JsonPrimitives.asBool(json['inspectionActive']),
      readOnlyMode: JsonPrimitives.asBool(json['readOnlyMode'], fallback: isStatusActive),
      activeInspectionId: json['inspectionId'] != null
          ? JsonPrimitives.asInt(json['inspectionId'])
          : (json['activeInspectionId'] != null ? JsonPrimitives.asInt(json['activeInspectionId']) : null),
      inspectorName: JsonPrimitives.asStringOrNull(json['inspectorName']),
    );
  }

  static List<DotInspectionCycleDay> fromCycleJson(List<dynamic> raw) {
    return raw
        .whereType<Map<String, dynamic>>()
        .map(fromCycleDayJson)
        .toList(growable: false);
  }

  static DotInspectionCycleDay fromCycleDayJson(Map<String, dynamic> json) {
    final driverObj = json['driver'] is Map<String, dynamic> ? json['driver'] as Map<String, dynamic> : null;
    final vehicleObj = json['vehicle'] is Map<String, dynamic> ? json['vehicle'] as Map<String, dynamic> : null;
    final eldObj = json['eld'] is Map<String, dynamic> ? json['eld'] as Map<String, dynamic> : null;
    final carrierObj = json['carrier'] is Map<String, dynamic> ? json['carrier'] as Map<String, dynamic> : null;
    final odo = json['odometer'] is Map<String, dynamic> ? json['odometer'] as Map<String, dynamic> : null;
    final eng = json['engineHours'] is Map<String, dynamic> ? json['engineHours'] as Map<String, dynamic> : null;

    final startOdo = odo != null ? JsonPrimitives.asDouble(odo['start']) : JsonPrimitives.asDouble(json['startOdometerKm']);
    final endOdo = odo != null ? JsonPrimitives.asDouble(odo['end']) : JsonPrimitives.asDouble(json['endOdometerKm']);
    final totalOdo = odo != null ? JsonPrimitives.asDouble(odo['total']) : JsonPrimitives.asDouble(json['totalDistanceKm']);
    final engHours = eng != null
        ? JsonPrimitives.asDouble(eng['total'] ?? eng['start'])
        : JsonPrimitives.asDouble(json['engineHours']);

    return DotInspectionCycleDay(
      driverId: DriverId(JsonPrimitives.asInt(driverObj?['id'] ?? json['driverId'])),
      driverName: JsonPrimitives.asString(driverObj?['name'] ?? json['driverName']),
      logDate: JsonPrimitives.asDate(json['logDate']),
      displayDate: JsonPrimitives.asString(json['displayDate'] ?? json['logDate']),
      displayLocation: JsonPrimitives.asString(json['displayLocation']),
      certified: JsonPrimitives.asBool(driverObj?['certified'] ?? json['certified']),
      certifiedAt: JsonPrimitives.asDateOrNull(json['certifiedAt']),
      eldRegistrationId: JsonPrimitives.asString(eldObj?['registrationId'] ?? json['eldRegistrationId']),
      eldIdentifier: JsonPrimitives.asString(eldObj?['identifier'] ?? json['eldIdentifier']),
      eldProvider: JsonPrimitives.asString(eldObj?['provider'] ?? json['eldProvider']),
      vehicleNumber: JsonPrimitives.asString(vehicleObj?['name'] ?? json['vehicleNumber']),
      uniqueId: JsonPrimitives.asString(vehicleObj?['vin'] ?? driverObj?['uniqueId'] ?? json['uniqueId']),
      vin: JsonPrimitives.asString(vehicleObj?['vin'] ?? json['vin']),
      startOdometerKm: startOdo,
      endOdometerKm: endOdo,
      totalDistanceKm: totalOdo,
      engineHours: engHours,
      trailers: _extractTrailers(json['shipment']?['trailers'] ?? json['trailers']),
      shippingDocuments: _extractShippingDocs(json['shipment']?['shippingDocuments'] ?? json['shippingDocuments']),
      carrierName: JsonPrimitives.asString(carrierObj?['name'] ?? json['carrierName']),
      usdotNumber: JsonPrimitives.asString(carrierObj?['dotNumber'] ?? json['usdotNumber']),
      mainOfficeAddress: JsonPrimitives.asString(carrierObj?['mainOffice'] ?? json['mainOfficeAddress']),
      homeTerminalAddress: JsonPrimitives.asString(carrierObj?['homeTerminal'] ?? json['homeTerminalAddress']),
      activeDataDiagnostics: _extractDiagnostics(json['dataDiagnosticIndicator'] ?? json['activeDataDiagnostics']),
      activeDeviceMalfunctions: _extractMalfunctions(json['deviceMalfunctionIndicator'] ?? json['activeDeviceMalfunctions']),
      exemptDriver: JsonPrimitives.asBool(driverObj?['exemptDriver'] ?? json['exemptDriver']),
      exemptReason: JsonPrimitives.asStringOrNull(driverObj?['exemptReason'] ?? json['exemptReason']),
      hasUnidentifiedDriving: JsonPrimitives.asBool(
        driverObj?['hasUnidentifiedDrivingRecords'] ?? json['hasUnidentifiedDriving'],
      ),
      unidentifiedDrivingCount: JsonPrimitives.asInt(
        json['unidentifiedDrivingCount'],
      ),
    );
  }

  /// Extracts cycle days from the root inspection session (`GET /eld/inspections` or `GET /eld/inspections/start`).
  static List<DotInspectionCycleDay> cycleFromSessionJson(Map<String, dynamic> session) {
    final rawLogs = session['inspectionLogs'];
    if (rawLogs is! List || rawLogs.isEmpty) {
      if (session['cycle'] is List) {
        return fromCycleJson(session['cycle'] as List);
      }
      return const [];
    }

    final driverObj = session['driver'] is Map<String, dynamic> ? session['driver'] as Map<String, dynamic> : null;
    final vehicleObj = session['vehicle'] is Map<String, dynamic> ? session['vehicle'] as Map<String, dynamic> : null;
    final eldObj = session['eld'] is Map<String, dynamic> ? session['eld'] as Map<String, dynamic> : null;
    final carrierObj = session['carrier'] is Map<String, dynamic> ? session['carrier'] as Map<String, dynamic> : null;

    final days = <DotInspectionCycleDay>[];
    for (final item in rawLogs) {
      if (item is! Map<String, dynamic>) continue;
      final merged = Map<String, dynamic>.from(item);
      if (driverObj != null && !merged.containsKey('driver')) merged['driver'] = driverObj;
      if (vehicleObj != null && !merged.containsKey('vehicle')) merged['vehicle'] = vehicleObj;
      if (eldObj != null && !merged.containsKey('eld')) merged['eld'] = eldObj;
      if (carrierObj != null && !merged.containsKey('carrier')) merged['carrier'] = carrierObj;
      days.add(fromCycleDayJson(merged));
    }
    return days;
  }

  /// Extracts a single day's log from the root session.
  static DotInspectionLog logFromSessionJson(
    Map<String, dynamic> session, {
    DateTime? targetDate,
  }) {
    final rawLogs = session['inspectionLogs'];
    if (rawLogs is! List || rawLogs.isEmpty) {
      return fromLogJson(session);
    }

    final driverObj = session['driver'] is Map<String, dynamic> ? session['driver'] as Map<String, dynamic> : null;
    final coDriverObj = session['coDriver'] is Map<String, dynamic> ? session['coDriver'] as Map<String, dynamic> : null;
    final vehicleObj = session['vehicle'] is Map<String, dynamic> ? session['vehicle'] as Map<String, dynamic> : null;
    final eldObj = session['eld'] is Map<String, dynamic> ? session['eld'] as Map<String, dynamic> : null;
    final carrierObj = session['carrier'] is Map<String, dynamic> ? session['carrier'] as Map<String, dynamic> : null;

    Map<String, dynamic>? selectedItem;
    if (targetDate != null) {
      final targetStr = targetDate.toIso8601String().split('T').first;
      for (final item in rawLogs) {
        if (item is Map<String, dynamic>) {
          final logDateStr = JsonPrimitives.asString(item['logDate']);
          if (logDateStr.startsWith(targetStr)) {
            selectedItem = item;
            break;
          }
        }
      }
    }

    selectedItem ??= rawLogs.firstWhere(
      (e) => e is Map<String, dynamic>,
      orElse: () => <String, dynamic>{},
    ) as Map<String, dynamic>;

    final merged = Map<String, dynamic>.from(selectedItem);
    if (driverObj != null && !merged.containsKey('driver')) merged['driver'] = driverObj;
    if (coDriverObj != null && !merged.containsKey('coDriver')) merged['coDriver'] = coDriverObj;
    if (vehicleObj != null && !merged.containsKey('vehicle')) merged['vehicle'] = vehicleObj;
    if (eldObj != null && !merged.containsKey('eld')) merged['eld'] = eldObj;
    if (carrierObj != null && !merged.containsKey('carrier')) merged['carrier'] = carrierObj;

    return fromLogJson(merged);
  }

  /// Extracts all daily logs from the root session.
  static List<DotInspectionLog> allLogsFromSessionJson(Map<String, dynamic> session) {
    final rawLogs = session['inspectionLogs'];
    if (rawLogs is! List || rawLogs.isEmpty) {
      return [fromLogJson(session)];
    }

    final driverObj = session['driver'] is Map<String, dynamic> ? session['driver'] as Map<String, dynamic> : null;
    final coDriverObj = session['coDriver'] is Map<String, dynamic> ? session['coDriver'] as Map<String, dynamic> : null;
    final vehicleObj = session['vehicle'] is Map<String, dynamic> ? session['vehicle'] as Map<String, dynamic> : null;
    final eldObj = session['eld'] is Map<String, dynamic> ? session['eld'] as Map<String, dynamic> : null;
    final carrierObj = session['carrier'] is Map<String, dynamic> ? session['carrier'] as Map<String, dynamic> : null;

    final logs = <DotInspectionLog>[];
    for (final item in rawLogs) {
      if (item is! Map<String, dynamic>) continue;
      final merged = Map<String, dynamic>.from(item);
      if (driverObj != null && !merged.containsKey('driver')) merged['driver'] = driverObj;
      if (coDriverObj != null && !merged.containsKey('coDriver')) merged['coDriver'] = coDriverObj;
      if (vehicleObj != null && !merged.containsKey('vehicle')) merged['vehicle'] = vehicleObj;
      if (eldObj != null && !merged.containsKey('eld')) merged['eld'] = eldObj;
      if (carrierObj != null && !merged.containsKey('carrier')) merged['carrier'] = carrierObj;
      logs.add(fromLogJson(merged));
    }
    return logs;
  }

  static DotInspectionLog fromLogJson(Map<String, dynamic> json) {
    final driverObj = json['driver'] is Map<String, dynamic> ? json['driver'] as Map<String, dynamic> : null;
    final coDriverObj = json['coDriver'] is Map<String, dynamic> ? json['coDriver'] as Map<String, dynamic> : null;
    final vehicleObj = json['vehicle'] is Map<String, dynamic> ? json['vehicle'] as Map<String, dynamic> : null;
    final eldObj = json['eld'] is Map<String, dynamic> ? json['eld'] as Map<String, dynamic> : null;
    final carrierObj = json['carrier'] is Map<String, dynamic> ? json['carrier'] as Map<String, dynamic> : null;
    final odo = json['odometer'] is Map<String, dynamic> ? json['odometer'] as Map<String, dynamic> : null;
    final eng = json['engineHours'] is Map<String, dynamic> ? json['engineHours'] as Map<String, dynamic> : null;

    final startOdo = odo != null ? JsonPrimitives.asDouble(odo['start']) : JsonPrimitives.asDouble(json['startOdometerKm']);
    final endOdo = odo != null ? JsonPrimitives.asDouble(odo['end']) : JsonPrimitives.asDouble(json['endOdometerKm']);
    final totalOdo = odo != null ? JsonPrimitives.asDouble(odo['total']) : JsonPrimitives.asDouble(json['totalDistanceKm']);
    final engHours = eng != null
        ? JsonPrimitives.asDouble(eng['total'] ?? eng['start'])
        : JsonPrimitives.asDouble(json['engineHours']);

    final eventsRaw = json['graphGrid']?['events'] ?? json['events'];

    return DotInspectionLog(
      driverId: DriverId(JsonPrimitives.asInt(driverObj?['id'] ?? json['driverId'])),
      driverName: JsonPrimitives.asString(driverObj?['name'] ?? json['driverName']),
      logDate: JsonPrimitives.asDate(json['logDate']),
      displayDate: JsonPrimitives.asString(json['displayDate'] ?? json['logDate']),
      displayLocation: JsonPrimitives.asString(json['displayLocation']),
      certified: JsonPrimitives.asBool(driverObj?['certified'] ?? json['certified']),
      certifiedAt: JsonPrimitives.asDateOrNull(json['certifiedAt']),
      eldRegistrationId: JsonPrimitives.asString(eldObj?['registrationId'] ?? json['eldRegistrationId']),
      eldIdentifier: JsonPrimitives.asString(eldObj?['identifier'] ?? json['eldIdentifier']),
      eldProvider: JsonPrimitives.asString(eldObj?['provider'] ?? json['eldProvider']),
      vehicleNumber: JsonPrimitives.asString(vehicleObj?['name'] ?? json['vehicleNumber']),
      uniqueId: JsonPrimitives.asString(vehicleObj?['vin'] ?? driverObj?['uniqueId'] ?? json['uniqueId']),
      vin: JsonPrimitives.asString(vehicleObj?['vin'] ?? json['vin']),
      startOdometerKm: startOdo,
      endOdometerKm: endOdo,
      totalDistanceKm: totalOdo,
      engineHours: engHours,
      trailers: _extractTrailers(json['shipment']?['trailers'] ?? json['trailers']),
      shippingDocuments: _extractShippingDocs(json['shipment']?['shippingDocuments'] ?? json['shippingDocuments']),
      carrierName: JsonPrimitives.asString(carrierObj?['name'] ?? json['carrierName']),
      usdotNumber: JsonPrimitives.asString(carrierObj?['dotNumber'] ?? json['usdotNumber']),
      mainOfficeAddress: JsonPrimitives.asString(carrierObj?['mainOffice'] ?? json['mainOfficeAddress']),
      homeTerminalAddress: JsonPrimitives.asString(carrierObj?['homeTerminal'] ?? json['homeTerminalAddress']),
      activeDataDiagnostics: _extractDiagnostics(json['dataDiagnosticIndicator'] ?? json['activeDataDiagnostics']),
      activeDeviceMalfunctions: _extractMalfunctions(json['deviceMalfunctionIndicator'] ?? json['activeDeviceMalfunctions']),
      events: _parseEvents(eventsRaw),
      readOnly: JsonPrimitives.asBool(json['readOnly'], fallback: true),
      period24HourStartTime: JsonPrimitives.asLocalTime(
        json['periodStartingTime'] ?? json['period24HourStartTime'],
      ),
      driverLicenseNumber: JsonPrimitives.asStringOrNull(
        driverObj?['licenseNumber'] ?? json['driverLicenseNumber'],
      ),
      driverLicenseState: JsonPrimitives.asStringOrNull(
        driverObj?['licenseState'] ?? json['driverLicenseState'],
      ),
      coDriverName: JsonPrimitives.asStringOrNull(coDriverObj?['name'] ?? json['coDriverName']),
      coDriverId: (coDriverObj?['id'] != null
              ? JsonPrimitives.asInt(coDriverObj?['id'])
              : (json['coDriverId'] != null ? JsonPrimitives.asInt(json['coDriverId']) : null)),
    );
  }

  static String _extractTrailers(dynamic raw) {
    if (raw is List) {
      final list = raw.map((item) {
        if (item is Map) return item['trailerNumber'] ?? item['number'] ?? '';
        return item.toString();
      }).where((s) => s.toString().trim().isNotEmpty).toList();
      return list.join(', ');
    }
    return JsonPrimitives.asString(raw);
  }

  static String _extractShippingDocs(dynamic raw) {
    if (raw is List) {
      final list = raw.map((item) {
        if (item is Map) return item['documentNumber'] ?? item['number'] ?? '';
        return item.toString();
      }).where((s) => s.toString().trim().isNotEmpty).toList();
      return list.join(', ');
    }
    return JsonPrimitives.asString(raw);
  }

  static List<String> _extractDiagnostics(dynamic raw) {
    if (raw is bool) {
      return raw ? ['DATA_DIAGNOSTIC'] : const [];
    }
    return JsonPrimitives.asStringList(raw);
  }

  static List<String> _extractMalfunctions(dynamic raw) {
    if (raw is bool) {
      return raw ? ['MALFUNCTION'] : const [];
    }
    return JsonPrimitives.asStringList(raw);
  }

  static List<DotInspectionEvent> _parseEvents(Object? raw) {
    if (raw is! List) return const [];
    final list = <DotInspectionEvent>[];
    for (var i = 0; i < raw.length; i++) {
      final e = raw[i];
      if (e is! Map<String, dynamic>) continue;
      final seq = e['sequenceNumber'] != null ? JsonPrimitives.asInt(e['sequenceNumber']) : (i + 1);
      final timeStr = JsonPrimitives.asString(e['time'] ?? e['timeEt']);
      final codeStr = JsonPrimitives.asString(e['code'] ?? e['eventCode']);
      final typeStr = JsonPrimitives.asString(e['type'] ?? e['eventType'] ?? codeStr);
      final descStr = JsonPrimitives.asString(e['notes'] ?? e['description'] ?? codeStr);

      list.add(
        DotInspectionEvent(
          sequenceNumber: seq,
          timeEt: timeStr,
          eventCode: codeStr,
          eventType: typeStr,
          description: descStr,
          location: JsonPrimitives.asString(e['location']),
          odometer: JsonPrimitives.asDouble(e['odometer']),
          engineHours: JsonPrimitives.asDouble(e['engineHours']),
          origin: JsonPrimitives.asString(e['origin'] ?? 'AUTO'),
          notes: JsonPrimitives.asString(e['notes']),
          certificationEvent: JsonPrimitives.asBool(e['certificationEvent']),
        ),
      );
    }
    return list;
  }
}

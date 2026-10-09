class ConnectivityStatus {
  final String? connectionStatus;
  final String? vehicleName;
  final String? lastHeartbeat;
  final int? dataAgeSeconds;
  final bool? normalOperationAllowed;
  final bool? isReliable;
  final List<String> diagnostics;
  final List<String> malfunctions;
  final String? engineVersion;
  final String? deviceVersion;
  final String? eldIdentifier;

  /// `manualModeActive` — server-side §395.34 paper-log fallback flag.
  /// Null when the server did not report it (never assumed active).
  final bool? manualModeActive;
  final String? manualModeReason;

  /// `manualRecordingAllowed` — false means the server refuses the toggle.
  final bool? manualRecordingAllowed;

  final String? deviceStatus;
  final bool? autoDrivingAllowed;
  final List<String> alerts;
  final bool? isMotionDataAvailable;
  final bool? isLocationDataAvailable;
  final bool? isEngineDataAvailable;
  final double? currentSpeedKmh;
  final double? odometerKm;
  final double? engineHours;
  final bool? engineOn;

  const ConnectivityStatus({
    this.connectionStatus,
    this.vehicleName,
    this.lastHeartbeat,
    this.dataAgeSeconds,
    this.normalOperationAllowed,
    this.isReliable,
    this.diagnostics = const [],
    this.malfunctions = const [],
    this.engineVersion,
    this.deviceVersion,
    this.eldIdentifier,
    this.manualModeActive,
    this.manualModeReason,
    this.manualRecordingAllowed,
    this.deviceStatus,
    this.autoDrivingAllowed,
    this.alerts = const [],
    this.isMotionDataAvailable,
    this.isLocationDataAvailable,
    this.isEngineDataAvailable,
    this.currentSpeedKmh,
    this.odometerKm,
    this.engineHours,
    this.engineOn,
  });

  /// Prefill only a MAC-shaped identifier. Other ELD ids are not invented as MAC.
  String? get macAddress {
    final value = eldIdentifier?.trim();
    if (value == null) return null;
    return isMacAddress(value) ? value : null;
  }

  bool get hasDiagnostic => diagnostics.isNotEmpty;

  bool get hasMalfunction =>
      connectionStatus?.toUpperCase() == 'MALFUNCTION' || malfunctions.isNotEmpty;
}

/// A non-object body is an error. A missing status is not treated as connected.
ConnectivityStatus? parseConnectivityStatus(dynamic data) {
  final root = _asMap(data);
  if (root == null) return null;
  final nested = root['data'];
  if (nested != null && nested is! Map) return null;
  final body = _asMap(nested) ?? root;
  final diagnostics = _strings(body['activeDiagnostics']);
  final malfunctions = _strings(body['activeMalfunctions']);
  final alerts = _strings(body['alerts']) ?? [];
  if (diagnostics == null || malfunctions == null) return null;
  return ConnectivityStatus(
    connectionStatus: _text(body['connectionStatus']),
    vehicleName: _text(body['vehicleName']),
    lastHeartbeat: _text(body['lastHeartbeat'] ?? body['lastDataTime']),
    dataAgeSeconds: _int(body['dataAgeSeconds']),
    normalOperationAllowed: _bool(body['normalOperationAllowed']),
    isReliable: _bool(body['isReliable']),
    diagnostics: diagnostics,
    malfunctions: malfunctions,
    engineVersion: _text(body['engineVersion']),
    deviceVersion: _text(body['deviceVersion']),
    eldIdentifier: _text(body['eldIdentifier'] ?? body['macAddress']),
    manualModeActive: _bool(body['manualModeActive']),
    manualModeReason: _text(body['manualModeReason']),
    manualRecordingAllowed: _bool(body['manualRecordingAllowed']),
    deviceStatus: _text(body['deviceStatus']),
    autoDrivingAllowed: _bool(body['autoDrivingAllowed']),
    alerts: alerts,
    isMotionDataAvailable: _bool(body['isMotionDataAvailable']),
    isLocationDataAvailable: _bool(body['isLocationDataAvailable']),
    isEngineDataAvailable: _bool(body['isEngineDataAvailable']),
    currentSpeedKmh: _double(body['currentSpeedKmh']),
    odometerKm: _double(body['odometerKm']),
    engineHours: _double(body['engineHours']),
    engineOn: _bool(body['engineOn']),
  );
}

Map<String, dynamic>? _asMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return null;
}

String? _text(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return null;
  return text;
}

int? _int(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

bool? _bool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true') return true;
  if (text == 'false') return false;
  return null;
}

List<String>? _strings(dynamic value) {
  if (value == null) return const [];
  if (value is! List) return null;
  return value.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList();
}

/// `AA:BB:CC:DD:EE:FF` (or `-` separated). Shared by prefill and the
/// connection form so both agree on what a MAC looks like.
bool isMacAddress(String value) =>
    RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$').hasMatch(value.trim());

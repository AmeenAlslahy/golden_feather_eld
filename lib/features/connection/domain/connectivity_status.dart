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
  });

  /// Prefill only a MAC-shaped identifier. Other ELD ids are not invented as MAC.
  String? get macAddress {
    final value = eldIdentifier?.trim();
    if (value == null) return null;
    final mac = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
    return mac.hasMatch(value) ? value : null;
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

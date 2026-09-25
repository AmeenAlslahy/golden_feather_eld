import 'entities/vehicle.dart';

enum VehicleOperateRefusal {
  motionUnknown,
  vehicleMoving,
  identifierMissing,
  thresholdMissing,
}

/// Wire `uniqueId` only. Numeric list ids are not substituted.
String? readOperableUniqueId(String? uniqueId) {
  final id = uniqueId?.trim() ?? '';
  if (id.isEmpty || id == 'unknown' || id == 'No Vehicle') return null;
  return id;
}

/// Company-fleet browse is view. Operate only if this driver is assigned
/// and another driver is not already using the vehicle.
bool listedVehicleIsOperable({
  required bool browsingCompanyFleet,
  required Vehicle vehicle,
}) {
  if (vehicle.inUseByOther == true) return false;
  if (browsingCompanyFleet && vehicle.isAssigned != true) return false;
  return true;
}

/// Device guard only. It does not copy hours or mark a vehicle selected.
VehicleOperateRefusal? refuseVehicleOperate({
  required double? speedMps,
  required double thresholdKmh,
  required String? uniqueId,
}) {
  if (!thresholdKmh.isFinite || thresholdKmh <= 0) {
    return VehicleOperateRefusal.thresholdMissing;
  }
  if (speedMps == null || !speedMps.isFinite) {
    return VehicleOperateRefusal.motionUnknown;
  }
  if (speedMps * 3.6 >= thresholdKmh) return VehicleOperateRefusal.vehicleMoving;
  final id = uniqueId?.trim() ?? '';
  if (id.isEmpty || id == 'unknown' || id == 'No Vehicle') {
    return VehicleOperateRefusal.identifierMissing;
  }
  return null;
}

/// A missing list is an error. An empty list is an empty success.
/// A row without `uniqueId` or `vehicleId` is not given an invented id.
List<Vehicle>? parseVehicleList(dynamic data) {
  final raw = _vehicleRows(data);
  if (raw == null) return null;
  final vehicles = <Vehicle>[];
  for (final item in raw) {
    final row = _asMap(item);
    if (row == null) return null;
    final vehicle = readVehicle(row);
    if (vehicle == null) return null;
    vehicles.add(vehicle);
  }
  return vehicles;
}

Vehicle? readVehicle(Map<String, dynamic> json) {
  final uniqueId = _text(json['uniqueId']);
  final vehicleId = _text(json['vehicleId'] ?? json['id']);
  final id = uniqueId ?? vehicleId;
  if (id == null) return null;
  final assigned = _bool(json['assignedToCurrentDriver']);
  final mine = _bool(json['myVehicle']);
  return Vehicle(
    id: id,
    uniqueId: uniqueId,
    name: _text(json['vehicleName'] ?? json['name']) ?? '',
    year: _text(json['model'] ?? json['year']) ?? '',
    type: _text(json['category']),
    vin: _text(json['vin']),
    operationalStatus: _text(json['operationalStatus']),
    statusReason: _text(json['statusReason']),
    isAssigned: assigned == true || mine == true,
    inUseByOther: _bool(json['inUseByOtherDriver']),
    selectedByServer: _bool(json['selected']),
    activeForCurrentDriver: _bool(
      json['activeForCurrentDriver'] ?? json['currentlyUsedByCurrentDriver'],
    ),
  );
}

/// Prefer the server sentence. Otherwise name the HTTP result, do not invent a policy.
String vehicleOperateFailure({
  required String code,
  String? serverMessage,
  int? statusCode,
}) {
  final message = serverMessage?.trim();
  if (message != null && message.isNotEmpty) return message;
  switch (statusCode) {
    case 400:
      return 'rejected';
    case 403:
      return 'unauthorized';
    case 404:
    case 503:
      return 'unavailable';
    case 409:
      return 'in_use';
    default:
      return code;
  }
}

List<dynamic>? _vehicleRows(dynamic data) {
  if (data is List) return data;
  final root = _asMap(data);
  if (root == null) return null;
  final nested = root['data'];
  if (nested is List) return nested;
  final body = _asMap(nested) ?? root;
  for (final key in ['vehicles', 'items', 'content', 'records']) {
    final value = body[key];
    if (value is List) return value;
  }
  return null;
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

bool? _bool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true') return true;
  if (text == 'false') return false;
  return null;
}

import 'dart:convert';

/// PNG signature bytes for `signatureData`. A local id is not a signature.
String? dvirSignatureData(List<int>? bytes) {
  if (bytes == null || bytes.isEmpty) return null;
  return base64Encode(bytes);
}

List<Map<String, dynamic>> dvirDefects({
  String? vehicle,
  String? trailer,
  List<Map<String, dynamic>> catalog = const [],
}) {
  final defects = <Map<String, dynamic>>[...catalog];
  final vehicleText = vehicle?.trim() ?? '';
  final trailerText = trailer?.trim() ?? '';
  if (vehicleText.isNotEmpty) {
    defects.add({
      'itemName': 'Vehicle defect',
      'category': 'VEHICLE',
      'description': vehicleText,
    });
  }
  if (trailerText.isNotEmpty) {
    defects.add({
      'itemName': 'Trailer defect',
      'category': 'TRAILER',
      'description': trailerText,
    });
  }
  return defects;
}

/// Returns null when a required create field is missing. Does not invent an id.
Map<String, dynamic>? buildDvirCreateBody({
  required int? driverId,
  required String uniqueId,
  required String status,
  required String? signatureData,
  required String inspectionTime,
  String? location,
  double? odometer,
  String? trailerNumber,
  String? companyName,
  String? remarks,
  String? vehicleDefects,
  String? trailerDefects,
  List<Map<String, dynamic>> catalogDefects = const [],
}) {
  final vehicle = uniqueId.trim();
  final signature = signatureData?.trim() ?? '';
  if (driverId == null || driverId <= 0) return null;
  if (vehicle.isEmpty || vehicle == 'No Vehicle') return null;
  if (status.trim().isEmpty) return null;
  if (signature.isEmpty || signature.startsWith('signature_')) return null;
  return {
    'driverId': driverId,
    'uniqueId': vehicle,
    'vehicleName': vehicle,
    'inspectionType': 'Pre-Trip',
    'inspectionTime': inspectionTime,
    'location': location,
    'odometer': odometer,
    'trailerNumber': trailerNumber,
    'companyName': companyName,
    'remarks': remarks,
    'status': status.trim(),
    'defects': dvirDefects(
      vehicle: vehicleDefects,
      trailer: trailerDefects,
      catalog: catalogDefects,
    ),
    'signatureData': signature,
  };
}

bool switchBlockedByKnownMotion({
  required double? speedMetersPerSecond,
  required double thresholdKmh,
}) {
  if (speedMetersPerSecond == null) return false;
  return speedMetersPerSecond * 3.6 >= thresholdKmh;
}

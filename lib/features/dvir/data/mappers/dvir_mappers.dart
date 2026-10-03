import '../../domain/dvir_catalog.dart';
import '../../domain/entities/dvir_report.dart';
import '../../domain/dvir_vehicle.dart';

/// بناء أجسام الطلب وقراءة أجسام الخادم لـ DVIR — كل التعامل مع الـ wire
/// هنا في طبقة البيانات.

/// Reads the catalog from the live envelope. Returns null when the body is
/// unreadable. Accepts the observed keys (`code`/`name`/`nameAr`/
/// `statutoryMandatory`/`criticalSafety`) and the schema keys
/// (`itemCode`/`itemName`/`safetyAffecting`).
List<DvirCatalogItem>? parseDvirCatalog(Object? body) {
  final list = _findList(body);
  if (list == null) return null;
  final items = <DvirCatalogItem>[];
  for (final raw in list) {
    if (raw is! Map) continue;
    final code = _text(raw['code'] ?? raw['itemCode']);
    final name = _text(raw['name'] ?? raw['itemName']);
    if (code == null || name == null) continue;
    items.add(
      DvirCatalogItem(
        code: code,
        name: name,
        nameAr: _text(raw['nameAr']),
        category: _text(raw['category']) ?? '',
        mandatory:
            raw['statutoryMandatory'] == true || raw['mandatory'] == true,
        critical:
            raw['criticalSafety'] == true ||
            raw['safetyAffecting'] == true ||
            raw['outOfService'] == true,
      ),
    );
  }
  return items;
}

List<dynamic>? _findList(Object? body) {
  if (body is List) return body;
  if (body is! Map) return null;
  for (final key in const ['items', 'catalog', 'defects', 'data', 'content']) {
    final value = body[key];
    if (value is List) return value;
    if (value is Map) {
      final nested = _findList(value);
      if (nested != null) return nested;
    }
  }
  return null;
}

String? _text(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

/// Wire shape of `DvirDefectItem` on `InsertDvirRequest`.
Map<String, dynamic> defectSelectionToWire(DvirDefectSelection selection) {
  final note = selection.description?.trim() ?? '';
  return {
    'itemCode': selection.item.code,
    'itemName': selection.item.name,
    'category': selection.item.category,
    if (selection.severity != null) 'severity': selection.severity!.wire,
    'stage': selection.stage.wire,
    'safetyAffecting': selection.item.critical,
    if (note.isNotEmpty) 'description': note,
  };
}

List<Map<String, dynamic>> _defects({
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
  required int? deviceId,
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
  // الخادم يرفض إنشاء الفحص بلا معرف جهاز المركبة (deviceId) — لا
  // جسم ناقص ولا اختراع قيمة.
  if (deviceId == null || deviceId <= 0) return null;
  // "No Vehicle" اسم معروض من لوحة القيادة، وليس مركبة — ولا جسم فارغ.
  if (isUnassignedVehicleId(vehicle)) return null;
  if (status.trim().isEmpty) return null;
  if (signature.isEmpty || signature.startsWith('signature_')) return null;
  if (odometer != null &&
      (odometer < 0 || odometer.isNaN || odometer.isInfinite)) {
    return null;
  }
  final defects = _defects(
    vehicle: vehicleDefects,
    trailer: trailerDefects,
    catalog: catalogDefects,
  );
  // DVIR-09: تقرير بعيوب لا يُقبل على السلك بحالة "سليمة" — مصالحة
  // إلزامية إلى Has Defects (اتساق SRS 7.1/7.6، لا تناقض قانوني).
  var wireStatus = status.trim();
  if (defects.isNotEmpty &&
      wireStatus == DvirConditionStatus.satisfactory.wire) {
    wireStatus = DvirConditionStatus.hasDefects.wire;
  }
  return {
    'driverId': driverId,
    'deviceId': deviceId,
    'uniqueId': vehicle,
    'vehicleName': vehicle,
    'inspectionType': 'Pre-Trip',
    'inspectionTime': inspectionTime,
    'location': location,
    'odometer': odometer,
    'trailerNumber': trailerNumber,
    'companyName': companyName,
    'remarks': remarks,
    'status': wireStatus,
    'defects': defects,
    'signatureData': signature,
  };
}

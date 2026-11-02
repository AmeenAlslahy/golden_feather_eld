import 'package:uuid/uuid.dart';
import '../../../../backend/adapters/eld_engine/models/dvir_dto.dart';
import '../../domain/defect_enums.dart';
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
    final name = _text(raw['nameEnglish'] ?? raw['name'] ?? raw['itemName']);
    if (code == null || name == null) continue;
    items.add(
      DvirCatalogItem(
        code: code,
        name: name,
        nameAr: _text(raw['nameArabic'] ?? raw['nameAr']),
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

/// Maps a server DVIR record into the domain entity.
///
/// The wire status is preserved exactly (unknown stays unknown); only the
/// coarse [VehicleCondition] is derived from it.
DvirReport mapDvirDtoToReport(DvirDto dto) {
  final conditionStatus = DvirConditionStatus.fromWire(dto.status);
  return DvirReport(
    id: dto.id.toString(),
    type: _parseInspectionType(dto.inspectionType),
    date: _parseDate(dto),
    driverName: dto.driver?.name ?? '',
    vehicleId:
        (dto.uniqueId?.isNotEmpty == true ? dto.uniqueId : dto.vehicleName) ??
        '',
    trailerId: dto.trailerNumber,
    odometer: dto.odometer,
    condition: _vehicleConditionFrom(conditionStatus),
    conditionStatus: conditionStatus,
    signature: dto.signatureData,
    notes: dto.remarks,
    isSubmitted: true,
    location: dto.location,
    companyName: dto.companyName,
    hasDefects: dto.hasDefects,
    defectsCount: dto.defectsCount,
    defectsSummary: dto.defectsSummary,
    outOfService: dto.outOfService,
    certified: dto.certified,
    mechanicName: dto.mechanicName,
    repairStatus: dto.repairStatus,
    repairNotes: dto.repairNotes,
    reviewingDriverName: dto.reviewingDriverName,
    nextDriverReviewed: dto.nextDriverReviewed,
    selectedDefects: [
      for (final defect in dto.defects)
        if ((defect.itemCode ?? '').trim().isNotEmpty ||
            (defect.itemName ?? '').trim().isNotEmpty)
          DvirDefectSelection(
            item: DvirCatalogItem(
              code: defect.itemCode?.trim() ?? 'GENERIC',
              name: defect.itemName ?? defect.itemCode ?? 'Unknown defect',
              category: defect.category ?? '',
              critical: defect.safetyAffecting || defect.outOfService,
            ),
            description: defect.description,
            severity: DefectSeverity.fromWire(defect.severity),
            stage: DefectLifecycleStage.fromWire(defect.stage),
          ),
    ],
    photos: dto.photos,
    trailers: dto.trailers
        .map(
          (t) => DvirTrailer(
            trailerNumber: t.trailerNumber,
            defects: t.defects
                .map((d) => d.description ?? d.itemName ?? '')
                .where((s) => s.isNotEmpty)
                .toList(),
          ),
        )
        .toList(),
  );
}

DateTime? _parseDate(DvirDto dto) {
  final raw = dto.inspectionTime?.trim();
  if (raw != null && raw.isNotEmpty) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
  }
  final created = dto.createdAt?.trim();
  if (created != null && created.isNotEmpty) {
    final parsed = DateTime.tryParse(created);
    if (parsed != null) return parsed;
  }
  return null;
}

InspectionType _parseInspectionType(String? type) {
  // The server sends wire values ("Post-Trip" / "Pre-Trip"), not Dart names.
  final t = type?.trim().toLowerCase() ?? '';
  if (t == 'post-trip' || t == 'post_trip' || t == 'posttrip') {
    return InspectionType.postTrip;
  }
  return InspectionType.preTrip;
}

VehicleCondition _vehicleConditionFrom(DvirConditionStatus status) {
  // Unknown or any non-satisfactory wire status stays conservative.
  return status == DvirConditionStatus.satisfactory
      ? VehicleCondition.safe
      : VehicleCondition.needsRepair;
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
  String inspectionType = 'Pre-Trip',
  String? location,
  double? odometer,
  String? trailerNumber,
  String? companyName,
  String? remarks,
  String? vehicleDefects,
  String? trailerDefects,
  String? clientUuid,
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
  // DVIR-09: تقرير بعيوب لا يُقبل على السلك بحالة "سليمة" — المصالحة
  // تُطبَّق مرة واحدة في domain، مع إبقاء أي نص غير معروف كما وصل.
  final requestedStatus = DvirConditionStatus.fromWire(status);
  final wireStatus = requestedStatus == DvirConditionStatus.unknown
      ? status.trim()
      : requestedStatus.resolvedFor(hasDefects: defects.isNotEmpty).wire;

  // الموقع نص كما كتبه السائق (عقد openapi: location string) — لا يُسقط
  // أبدًا. الإحداثيات حقول عُليا منفصلة تُشتق فقط حين يُحلَّل النص كزوج
  // "lat, lon" كامل؛ زوج ناقص يعني لا إحداثيات، ولا اختراع قيم.
  final locationText = location?.trim() ?? '';
  double? latitude;
  double? longitude;
  if (locationText.isNotEmpty) {
    final parts = locationText.split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0].trim());
      final lon = double.tryParse(parts[1].trim());
      if (lat != null && lon != null) {
        latitude = lat;
        longitude = lon;
      }
    }
  }

  List<Map<String, dynamic>> extractDetects(
    String category,
    String? customNote,
  ) {
    final list = catalogDefects
        .where((d) => d['category'] == category)
        .map(
          (d) => {
            if (d['itemCode'] != null) 'itemCode': d['itemCode'],
            'itemName': d['itemName'],
            if (d['severity'] != null) 'severity': d['severity'],
            if (d['stage'] != null) 'stage': d['stage'],
            if (d['description'] != null) 'description': d['description'],
          },
        )
        .toList();
    if (customNote != null && customNote.trim().isNotEmpty) {
      list.add({
        'itemName': category == 'VEHICLE' ? 'Vehicle defect' : 'Trailer defect',
        'description': customNote.trim(),
      });
    }
    return list;
  }

  return {
    // Top-level fields (Legacy + New)
    'driverId': driverId,
    'deviceId': deviceId,
    'uniqueId': vehicle,
    'vehicleName': vehicle,
    'inspectionType': inspectionType.toUpperCase().replaceAll('-', '_'),
    'inspectionTime': inspectionTime,
    if (locationText.isNotEmpty) 'location': locationText,
    if (latitude != null && longitude != null) ...{
      'latitude': latitude,
      'longitude': longitude,
    },
    'odometer': odometer,
    'trailerNumber': trailerNumber,
    'companyName': companyName,
    'remarks': remarks,
    'status': wireStatus,
    'signature': signature,
    'signatureData': signature,
    'clientUuid': clientUuid ?? const Uuid().v4(),
    'syncStatus': 'SYNCED',
    'defects': defects, // Legacy flat defects

    // Swagger root defect arrays
    'vehicleDefects': [
      if (vehicleDefects != null && vehicleDefects.trim().isNotEmpty)
        vehicleDefects.trim(),
      ...catalogDefects
          .where((d) => d['category'] == 'VEHICLE')
          .map((d) => d['itemName']?.toString() ?? '')
          .where((s) => s.isNotEmpty),
    ],
    'trailerDefects': [
      if (trailerDefects != null && trailerDefects.trim().isNotEmpty)
        trailerDefects.trim(),
      ...catalogDefects
          .where((d) => d['category'] == 'TRAILER')
          .map((d) => d['itemName']?.toString() ?? '')
          .where((s) => s.isNotEmpty),
    ],

    // New nested fields as per Swagger
    'vehicle': {
      'uniqueId': vehicle,
      'deviceId': deviceId,
      'detects': extractDetects('VEHICLE', vehicleDefects),
    },
    'trailers': trailerNumber != null && trailerNumber.isNotEmpty
        ? trailerNumber
              .split(',')
              .map(
                (t) => {
                  'trailerNumber': t.trim(),
                  'detects': extractDetects('TRAILER', trailerDefects),
                },
              )
              .toList()
        : [],
    'trailerNumbers': trailerNumber != null && trailerNumber.isNotEmpty
        ? trailerNumber.split(',').map((t) => t.trim()).toList()
        : [],
  };
}

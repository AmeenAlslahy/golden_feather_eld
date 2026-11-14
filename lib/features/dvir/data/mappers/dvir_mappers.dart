import 'package:uuid/uuid.dart';
import '../../../../backend/adapters/eld_engine/models/dvir_dto.dart';
import '../../domain/defect_enums.dart';
import '../../domain/dvir_catalog.dart';
import '../../domain/dvir_location.dart';
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
    vehicleName: dto.vehicleName,
    trailerId: dto.trailerNumber,
    odometer: dto.odometer,
    condition: _vehicleConditionFrom(conditionStatus),
    conditionStatus: conditionStatus,
    signature: dto.signatureData,
    notes: dto.remarks,
    isSubmitted: true,
    location: dto.location,
    latitude: dto.latitude,
    longitude: dto.longitude,
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
    serverRetentionUntil: dto.retentionUntil != null
        ? DateTime.tryParse(dto.retentionUntil!)
        : null,
    selectedDefects: [
      for (final defect in dto.defects)
        if ((defect.itemCode ?? '').trim().isNotEmpty ||
            (defect.itemName ?? '').trim().isNotEmpty)
          _mapDefectToSelection(defect),
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

DvirDefectSelection _mapDefectToSelection(DvirDefectDto defect) {
  final code = defect.itemCode?.trim() ?? 'GENERIC';
  final rawName = defect.itemName ?? defect.itemCode ?? 'Unknown defect';
  final standard = kStandardTrailerDefectItems
      .where((i) => i.code.toLowerCase() == code.toLowerCase())
      .firstOrNull;
  final name = standard?.name ??
      (rawName.toUpperCase() == code.toUpperCase()
          ? _humanizeDefectCode(rawName)
          : rawName);
  final nameAr = standard?.nameAr;

  return DvirDefectSelection(
    item: DvirCatalogItem(
      code: code,
      name: name,
      nameAr: nameAr,
      category: defect.category ?? standard?.category ?? '',
      critical: defect.safetyAffecting ||
          defect.outOfService ||
          (standard?.critical ?? false),
    ),
    description: defect.description,
    severity: DefectSeverity.fromWire(defect.severity),
    stage: DefectLifecycleStage.fromWire(defect.stage),
  );
}

String _humanizeDefectCode(String code) {
  return code
      .split('_')
      .where((s) => s.isNotEmpty)
      .map(
        (s) => s.length > 1
            ? s[0].toUpperCase() + s.substring(1).toLowerCase()
            : s.toUpperCase(),
      )
      .join(' ');
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
  double? latitude,
  double? longitude,
  DvirCoordinates? coordinates,
  double? odometer,
  String? trailerNumber,
  String? companyName,
  String? remarks,
  String? vehicleDefects,
  String? trailerDefects,
  String? clientUuid,
  String? timeZone,
  List<String> photos = const [],
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
  // العقد الحيّ لـ POST /eld/dvir (المثال الذي نجح 200) لا يحتوي حقل
  // `defects` إطلاقاً: العيوب تُرسل كأسماء نصية في `vehicle.detects` و
  // `trailers[].detects` و`vehicleDefects`/`trailerDefects` فقط. إرسال
  // `defects` ككائنات كان سبب 400:
  // "Cannot deserialize value of type `java.lang.String` from Object value
  // ... InsertDvirRequest["defects"]->ArrayList[0]".
  //
  // نطاق العيب يُقرأ بقاعدة النطاق نفسها (`TRAILER` وإلا مركبة): كتالوج
  // المركبة الحيّ يرسل `category` فارغاً، فمقارنة `== 'VEHICLE'` كانت
  // تُسقط عيوب المركبة بصمت.
  bool isTrailerDefect(Map<String, dynamic> defect) =>
      (defect['category']?.toString().trim().toUpperCase() ?? '') == 'TRAILER';

  List<String> uniqueNames(Iterable<String> values) {
    final seen = <String>{};
    return [
      for (final value in values)
        if (value.isNotEmpty && seen.add(value)) value,
    ];
  }

  List<String> extractDetects(bool trailer, String? customNote) {
    // تُرسل **أكواد** الكتالوج لا أسماؤها (قرار المالك): كود قصير ثابت لا
    // يتغير باللغة ولا ينفجر فوق حد varchar(50) في eld_dvir_defects الذي
    // فجّر اسماً من 46 حرفاً بعد اشتقاق الخادم له، ويتفرد لكل عيب فتُنشأ
    // سجل واحد لكل اختيار بدل الازدواجية العربية/الإنجليزية. الخادم يخزن
    // السلسلة كما وردت بلا مطابقة كتالوج (رد 200: itemCode="STRING" من
    // "string") — فأسماء العرض تُشتق لاحقاً من الكود عند الخادم.
    // نص العيوب المشتق محلياً (عرض مترجم لنفس الاختيارات) لا يُرسل عند
    // وجود أكواد للنطاق — وإلا عادت الأسماء الطويلة كسجلات مضاعفة. يبقى
    // بديلاً فقط للنطاق الخالي من الكتالوج.
    final hasCatalog = catalogDefects.any((d) => isTrailerDefect(d) == trailer);
    return uniqueNames([
      if (!hasCatalog && customNote != null && customNote.trim().isNotEmpty)
        customNote.trim(),
      for (final defect in catalogDefects)
        if (isTrailerDefect(defect) == trailer)
          (defect['itemCode'] ?? defect['itemName'])?.toString().trim() ?? '',
    ]);
  }

  // القائمة المسطحة تجمع نطاقي المركبة والمقطورة — أسماء فقط.
  final vehicleDetects = extractDetects(false, vehicleDefects);
  final trailerDetects = extractDetects(true, trailerDefects);
  final defects = uniqueNames([...vehicleDetects, ...trailerDetects]);
  // DVIR-09: تقرير بعيوب لا يُقبل على السلك بحالة "سليمة" — المصالحة
  // تُطبَّق مرة واحدة في domain، مع إبقاء أي نص غير معروف كما وصل.
  final requestedStatus = DvirConditionStatus.fromWire(status);
  final wireStatus = requestedStatus == DvirConditionStatus.unknown
      ? status.trim()
      : requestedStatus.resolvedFor(hasDefects: defects.isNotEmpty).wire;

  // الموقع: العقد الحيّ يستقبل كائن `location: {latitude, longitude}`.
  // لا يُرسل نص حر لأن نوع الحقل كائن — النص يبقى محلياً في التقرير ولا
  // تُخترع له إحداثيات.
  final resolvedCoords = coordinates ??
      dvirCoordinatesFrom(latitude, longitude) ??
      parseDvirLocationText(location);
  final trailerNumbers = (trailerNumber ?? '')
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  // الحقول هنا مطابقة لعقد POST /eld/dvir الحيّ فقط — لا حقول إضافية
  // (deviceId/uniqueId/vehicleName/locationText/signatureData/trailerNumber/
  // companyName/defects/trailerNumbers) لأن الخادم لا يعرّفها في الطلب.
  return {
    'driverId': driverId,
    'clientUuid': clientUuid ?? const Uuid().v4(),
    'inspectionType': inspectionType.toUpperCase().replaceAll('-', '_'),
    'inspectionTime': inspectionTime,
    'timeZone': timeZone ?? DateTime.now().timeZoneName,
    if (resolvedCoords != null) 'location': resolvedCoords.toWire(),
    'photos': photos
        .map((p) => {'fileName': p.split('/').last.split(r'\').last})
        .toList(),
    if (odometer != null) 'odometer': odometer,
    'vehicle': {
      // الخادم يحل الجهاز من vehicle.uniqueId وحده ويتجاهل معرفاتنا
      // الرقمية الصريحة: التجربة الناجحة 200 (uniqueId="485" → deviceId 485
      // في الرد)، ومحاولة مطابقة العقد بمعرفنا النصي أعادت NPE
      // "deviceId cannot be null" في DvirDefect.createNew:91 رغم إرسال
      // deviceId=503 في الجذر وداخل vehicle. المعرّف القابل للحل المثبت
      // هو الرقمي — يُرسل كسلسلة هنا، والمعرف النصي يبقى محليًا.
      'uniqueId': deviceId.toString(),
      'detects': vehicleDetects,
    },
    'trailers': [
      for (final number in trailerNumbers)
        {'trailerNumber': number, 'detects': trailerDetects},
    ],
    if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks.trim(),
    'status': wireStatus,
    // التوقيع يُرسل بصيغة data URL مطابقة للعقد الحيّ الناجح (200: الطلب
    // بـ "data:image/png;base64,..." ورده أعادها ببادئتها في signatureData).
    // إرسال base64 مجردة جعل signatureData يعود فارغاً من تفاصيل التقرير
    // فاختفى القسم كله — إن كان الخادم يفصل البادئة قبل التخزين.
    'signature': signature.startsWith('data:')
        ? signature
        : 'data:image/png;base64,$signature',
    'syncStatus': 'SYNCED',
    'vehicleDefects': vehicleDetects,
    'trailerDefects': trailerDetects,
  };
}

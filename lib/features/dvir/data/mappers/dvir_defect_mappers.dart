import '../../domain/entities/dvir_defect.dart';

/// تحليل عيب DVIR من رد الخادم — يُعيد null للجسم غير المقروء بدل اختراع
/// قيم؛ الحقول الغائبة تبقى null في الكيان.
DvirDefect? parseDvirDefect(Object? raw) {
  if (raw is! Map) return null;
  final json = raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw);
  final id = json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}');
  if (id == null) return null;

  return DvirDefect(
    id: id,
    inspectionId: _asInt(json['inspectionId']),
    deviceId: _asInt(json['deviceId']),
    driverId: _asInt(json['driverId']),
    assetType: _asString(json['assetType']),
    assetIdentifier: _asString(json['assetIdentifier']),
    itemCode: _asString(json['itemCode']),
    itemName: _asString(json['itemName']),
    description: _asString(json['description']),
    severity: _asString(json['severity']),
    stage: _asString(json['stage']),
    outOfService: json['outOfService'] is bool ? json['outOfService'] as bool : null,
    repairDeadline: DateTime.tryParse('${json['repairDeadline'] ?? ''}'),
    repairActions: _asList(json['repairActions'])
        ?.map(_parseRepairAction)
        .toList(growable: false) ?? const [],
    certifications: _asList(json['certifications'])
        ?.map(_parseCertification)
        .toList(growable: false) ?? const [],
  );
}

/// قائمة عيوب نشطة: تقبل List مباشرة أو مغلّفاً بـ data/items.
List<DvirDefect>? parseDvirDefectList(Object? body) {
  List<dynamic> rows;
  if (body is List) {
    rows = body;
  } else if (body is Map) {
    final data = body['data'] is List
        ? body['data'] as List
        : body['items'] is List
            ? body['items'] as List
            : body['defects'] is List
                ? body['defects'] as List
                : null;
    if (data == null) return null;
    rows = data;
  } else {
    return null;
  }
  final defects = <DvirDefect>[];
  for (final row in rows) {
    final defect = parseDvirDefect(row);
    if (defect == null) return null; // صف غير مقروء = جسم غير موثوق كله
    defects.add(defect);
  }
  return defects;
}

DvirRepairAction _parseRepairAction(Map raw) {
  return DvirRepairAction(
    id: _asInt(raw['id']),
    performedByName: _asString(raw['performedByName']),
    actionPerformed: _asString(raw['actionPerformed']),
    repairNotes: _asString(raw['repairNotes']),
    workOrderNumber: _asString(raw['workOrderNumber']),
    performedAt: DateTime.tryParse('${raw['performedAt'] ?? ''}'),
  );
}

DvirDefectCertification _parseCertification(Map raw) {
  return DvirDefectCertification(
    id: _asInt(raw['id']),
    certifiedByName: _asString(raw['certifiedByName']),
    certificationType: _asString(raw['certificationType']),
    certificationNotes: _asString(raw['certificationNotes']),
    certifiedAt: DateTime.tryParse('${raw['certifiedAt'] ?? ''}'),
  );
}

List<Map>? _asList(Object? raw) => raw is List ? raw.whereType<Map>().toList() : null;

int? _asInt(Object? raw) =>
    raw is int ? raw : (raw is String ? int.tryParse(raw) : null);

String? _asString(Object? raw) {
  final text = raw?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return null;
  return text;
}

import '../../domain/entities/unidentified_event.dart';

/// يقرأ شكل القائمة الحيّ: مصفوفة خام أو كائن يحتوي المصفوفة.
/// صفوف الخادم تحمل `id` (Duty Status ID) وليس معرّفًا محليًا.
List<Map<String, dynamic>> parseUnidentifiedList(Map<String, dynamic> json) {
  final raw =
      json['items'] ?? json['events'] ?? json['content'] ?? json['data'];
  if (raw is Map) {
    return parseUnidentifiedList(Map<String, dynamic>.from(raw));
  }
  if (raw is! List) return const [];
  return raw.whereType<Map>().map(normalizeUnidentifiedItem).toList();
}

/// يوحّد أسماء حقول الخادم قبل بناء الكيان.
Map<String, dynamic> normalizeUnidentifiedItem(Map<dynamic, dynamic> raw) {
  final item = Map<String, dynamic>.from(raw);
  return {
    'id': _asInt(item['id']),
    'deviceId': _asInt(item['deviceId']),
    'vehicleName': '${item['vehicleName'] ?? ''}',
    'vehicleVin': '${item['vehicleVin'] ?? ''}',
    'startTime': '${item['startTime'] ?? ''}',
    'endTime': '${item['endTime'] ?? ''}',
    'durationMinutes': _asInt(item['durationMinutes']),
    'durationFormatted': '${item['durationFormatted'] ?? ''}',
    'latitude': _asNum(item['latitude']),
    'longitude': _asNum(item['longitude']),
    'locationDescription': '${item['locationDescription'] ?? ''}',
    'odometerMiles': _asNum(item['odometerMiles']),
    'engineHours': _asNum(item['engineHours']),
    'status': '${item['status'] ?? ''}',
    'allocationType': '${item['allocationType'] ?? ''}',
    'allocatedToDriverId': _asInt(item['allocatedToDriverId']),
    'annotation': '${item['annotation'] ?? ''}',
    'rejectionReason': '${item['rejectionReason'] ?? ''}',
    'pendingOver8Days': item['pendingOver8Days'] == true,
  };
}

/// يحوّل استجابة الخادم إلى كيانات Domain.
List<UnidentifiedEvent> parseUnidentifiedEvents(Map<String, dynamic> json) {
  return parseUnidentifiedList(
    json,
  ).map((item) => UnidentifiedEventDto.fromMap(item).toEntity()).toList();
}

/// يحوّل حدثًا واحدًا من `GET /eld/unidentified/{id}` إلى كيان Domain.
UnidentifiedEvent parseUnidentifiedEvent(Map<String, dynamic> json) {
  final raw = json['event'] ?? json['data'] ?? json;
  final item = raw is Map
      ? normalizeUnidentifiedItem(Map<String, dynamic>.from(raw))
      : <String, dynamic>{};
  return UnidentifiedEventDto.fromMap(item).toEntity();
}

/// يقرأ ملخص `GET /eld/unidentified/summary`.
UnidentifiedSummary parseUnidentifiedSummary(Map<String, dynamic> json) {
  final raw = json['summary'] ?? json['data'] ?? json;
  final item = raw is Map
      ? Map<String, dynamic>.from(raw)
      : const <String, dynamic>{};
  return UnidentifiedSummary(
    totalUnclaimed: _asInt(item['totalUnclaimed']) ?? 0,
    totalRejected: _asInt(item['totalRejected']) ?? 0,
    pendingOver8DaysCount: _asInt(item['pendingOver8DaysCount']) ?? 0,
    complianceAlertActive: item['complianceAlertActive'] == true,
  );
}

class UnidentifiedEventDto {
  final Map<String, dynamic> _item;

  const UnidentifiedEventDto(this._item);

  factory UnidentifiedEventDto.fromMap(Map<String, dynamic> item) =>
      UnidentifiedEventDto(item);

  UnidentifiedEvent toEntity() {
    return UnidentifiedEvent(
      id: _item['id'] is int ? _item['id'] as int : null,
      deviceId: _item['deviceId'] is int ? _item['deviceId'] as int : null,
      vehicleName: '${_item['vehicleName'] ?? ''}',
      vehicleVin: '${_item['vehicleVin'] ?? ''}',
      startTime: '${_item['startTime'] ?? ''}',
      endTime: '${_item['endTime'] ?? ''}',
      durationMinutes: _asInt(_item['durationMinutes']),
      durationFormatted: '${_item['durationFormatted'] ?? ''}',
      latitude: _asNum(_item['latitude']),
      longitude: _asNum(_item['longitude']),
      locationDescription: '${_item['locationDescription'] ?? ''}',
      odometerMiles: _asNum(_item['odometerMiles']),
      engineHours: _asNum(_item['engineHours']),
      status: '${_item['status'] ?? ''}',
      allocationType: '${_item['allocationType'] ?? ''}',
      allocatedToDriverId: _asInt(_item['allocatedToDriverId']),
      annotation: '${_item['annotation'] ?? ''}',
      rejectionReason: '${_item['rejectionReason'] ?? ''}',
      pendingOver8Days: _item['pendingOver8Days'] == true,
    );
  }
}

int? _asInt(Object? value) => value is int ? value : int.tryParse('$value');

num? _asNum(Object? value) {
  if (value is num) return value;
  return num.tryParse('$value');
}

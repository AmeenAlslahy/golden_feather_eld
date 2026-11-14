/// إحداثيات موقع فحص DVIR — تُقرأ من GPS وتُعرض في حقل الموقع، ثم تُرسل
/// إلى الخادم ككائن `location: {latitude, longitude}`.
///
/// القاعدة هنا صرفة: لا تقرأ مزوّدات ولا تخترع قيمة. `null` تعني «لا موقع
/// صالح»، و(0, 0) هو ثابت «بلا موقع» المستخدم في بقية المشروع.
class DvirCoordinates {
  final double latitude;
  final double longitude;

  const DvirCoordinates({required this.latitude, required this.longitude});

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      (latitude != 0 || longitude != 0);

  Map<String, double> toWire() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DvirCoordinates &&
          other.latitude == latitude &&
          other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'DvirCoordinates($latitude, $longitude)';
}

/// يعيد null للقيم الغائبة أو غير الصالحة (NaN/لانهاية/0,0) — لا اختراع.
DvirCoordinates? dvirCoordinatesFrom(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) return null;
  final coordinates = DvirCoordinates(latitude: latitude, longitude: longitude);
  return coordinates.isValid ? coordinates : null;
}

/// الشكل الذي يُعرض في حقل الموقع: "lat, lon".
String formatDvirLocationText(DvirCoordinates coordinates) =>
    '${coordinates.latitude}, ${coordinates.longitude}';

/// يقرأ حقل الموقع كزوج "lat, lon" كامل. أي نص آخر — أو زوج ناقص أو
/// (0,0) — يعيد null، فيبقى النص كما كتبه السائق ولا تُخترع إحداثيات.
DvirCoordinates? parseDvirLocationText(String? text) {
  final value = text?.trim() ?? '';
  if (value.isEmpty) return null;
  final parts = value.split(',');
  if (parts.length != 2) return null;
  return dvirCoordinatesFrom(
    double.tryParse(parts[0].trim()),
    double.tryParse(parts[1].trim()),
  );
}

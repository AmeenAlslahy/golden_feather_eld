/// معرّفات "لا مركبة" ترد من طبقات أخرى (لوحة القيادة/الجهاز).
/// لا تُرسل إلى الخادم ولا تُبنى منها تقارير.
const String noVehicleSentinel = 'No Vehicle';

bool isUnassignedVehicleId(String? id) {
  final v = id?.trim() ?? '';
  return v.isEmpty || v.toLowerCase() == noVehicleSentinel.toLowerCase();
}

/// أضيق مرجع مركبة يحتاجه حل هوية فحص DVIR — يُبقي قاعدة النطاق نقية
/// بلا استيراد كيان مركبة الميزة الأخرى.
class DvirVehicleRef {
  final String id;
  final String? uniqueId;
  final int? deviceId;

  const DvirVehicleRef({required this.id, this.uniqueId, this.deviceId});
}

/// المصدر الوحيد لسؤال «أي مركبة يفحص هذا التقرير؟» — كان هذا الحل
/// مكرراً بين الصفحة والمزوّد، والآن دالة واحدة تستهلكهما.
///
/// الترتيب: الاختيار المحلي/المحدد أولاً، ثم معرّف لوحة القيادة محلولاً
/// عبر قائمة المركبات المحمّلة، ثم معرّف غير رقمي (هو uniqueId أصلاً)،
/// ثم أفضل مجهود عندما لا توجد قائمة محمّلة. `null` = لا شيء موثوق.
String? resolveDvirVehicleUniqueId({
  required List<DvirVehicleRef> vehicles,
  required String? selectedUniqueId,
  required String? dashboardVehicleId,
}) {
  final selected = selectedUniqueId?.trim();
  if (selected != null && !isUnassignedVehicleId(selected)) return selected;

  if (isUnassignedVehicleId(dashboardVehicleId)) return null;
  final dashId = dashboardVehicleId!.trim();
  for (final vehicle in vehicles) {
    final matches =
        vehicle.id.trim() == dashId || vehicle.uniqueId?.trim() == dashId;
    if (!matches) continue;
    final resolved = vehicle.uniqueId?.trim();
    if (resolved != null && !isUnassignedVehicleId(resolved)) return resolved;
  }
  if (vehicles.isEmpty) return dashId;
  if (int.tryParse(dashId) == null) return dashId;
  return null;
}

/// معرّف الجهاز الرقمي (Traccar deviceId) الذي يشترطه الخادم في
/// `POST /eld/dvir`: مركبة الاختيار المحلية المطابقة ← لوحة القيادة
/// (فقط عندما لا توجد مركبة محلية) ← أول مطابقة في قائمة المركبات.
/// لا اختراع قيم؛ `null` = الرفض.
int? resolveDvirDeviceId({
  required String? reportVehicleId,
  required DvirVehicleRef? selectedVehicle,
  required int? dashboardDeviceId,
  required List<DvirVehicleRef> vehicles,
}) {
  if (selectedVehicle != null &&
      selectedVehicle.uniqueId?.trim() == reportVehicleId?.trim() &&
      selectedVehicle.deviceId != null &&
      selectedVehicle.deviceId! > 0) {
    return selectedVehicle.deviceId;
  }
  if (selectedVehicle == null &&
      dashboardDeviceId != null &&
      dashboardDeviceId > 0) {
    return dashboardDeviceId;
  }
  for (final vehicle in vehicles) {
    if (vehicle.uniqueId?.trim() != reportVehicleId?.trim()) continue;
    final deviceId = vehicle.deviceId;
    if (deviceId != null && deviceId > 0) return deviceId;
  }
  return null;
}

/// قيمة المقطورة الابتدائية للفحص من مقطورة نموذج اليوم — قيم العرض
/// ("None"/"-") ليست مقطورة.
String initialDvirTrailerNumber(String? dashboardTrailerId) {
  final trailer = dashboardTrailerId?.trim();
  if (trailer == null ||
      trailer.isEmpty ||
      trailer == 'None' ||
      trailer == '-') {
    return '';
  }
  return trailer;
}

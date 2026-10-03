/// معرّفات "لا مركبة" ترد من طبقات أخرى (لوحة القيادة/الجهاز).
/// لا تُرسل إلى الخادم ولا تُبنى منها تقارير.
const String noVehicleSentinel = 'No Vehicle';

bool isUnassignedVehicleId(String? id) {
  final v = id?.trim() ?? '';
  return v.isEmpty || v.toLowerCase() == noVehicleSentinel.toLowerCase();
}

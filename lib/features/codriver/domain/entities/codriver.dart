/// كيان السائق المساعد
class CoDriver {
  final String id;
  final String name;
  final String? licenseNumber;

  const CoDriver({required this.id, required this.name, this.licenseNumber});

  static const CoDriver none = CoDriver(id: 'none', name: 'No One');
}

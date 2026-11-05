/// كيان السائق المساعد
class CoDriver {
  final String id;
  final String name;
  final String? licenseNumber;

  const CoDriver({required this.id, required this.name, this.licenseNumber});

  static const CoDriver none = CoDriver(id: 'none', name: 'No One');

  /// مصنع لتحليل السائق المساعد سواء كان مغلّفاً في استجابة OAS:
  /// `{ "driver": { "id": 102, "name": "أحمد خالد", "licenseNumber": "DL-CA-449102" }, "eligible": true }`
  /// أو مسطحاً:
  /// `{ "id": 102, "name": "أحمد خالد", "licenseNumber": "..." }`
  factory CoDriver.fromJson(Map<String, dynamic> json) {
    final driverMap = json['driver'] is Map<String, dynamic>
        ? json['driver'] as Map<String, dynamic>
        : (json['driver'] is Map
            ? Map<String, dynamic>.from(json['driver'] as Map)
            : null);

    final target = driverMap ?? json;
    final rawId = target['id'] ?? target['driverId'];
    final rawName =
        target['name'] ?? target['fullName'] ?? target['firstName'];
    final rawLicense = target['licenseNumber'] ??
        (target['attributes'] is Map
            ? target['attributes']['licenseNumber']
            : null);

    final cleanName = rawName?.toString().trim();
    return CoDriver(
      id: rawId?.toString() ?? '',
      name: (cleanName != null && cleanName.isNotEmpty) ? cleanName : 'Unknown',
      licenseNumber: rawLicense?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (licenseNumber != null) 'licenseNumber': licenseNumber,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoDriver &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          licenseNumber == other.licenseNumber;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ licenseNumber.hashCode;
}

/// تصنيف الأحداث غير المحددة كما تعرضه الشاشة.
///
/// لا يحمل قيمة الاتصال بالخادم: طبقة البيانات هي التي تحوّله إلى
/// `UnidentifiedTab` الخاص بعقد الـ backend.
enum UnidentifiedTab { unclaimed, rejected }

/// حدث قيادة غير محدد كما أعاده الخادم، بعد تطبيعه في طبقة البيانات.
class UnidentifiedEvent {
  final int? id;
  final int? deviceId;
  final String vehicleName;
  final String vehicleVin;
  final String startTime;
  final String endTime;
  final int? durationMinutes;
  final String durationFormatted;
  final num? latitude;
  final num? longitude;
  final String locationDescription;
  final num? odometerMiles;
  final num? engineHours;
  final String status;
  final String allocationType;
  final int? allocatedToDriverId;
  final String annotation;
  final String rejectionReason;
  final bool pendingOver8Days;

  const UnidentifiedEvent({
    this.id,
    this.deviceId,
    this.vehicleName = '',
    this.vehicleVin = '',
    this.startTime = '',
    this.endTime = '',
    this.durationMinutes,
    this.durationFormatted = '',
    this.latitude,
    this.longitude,
    this.locationDescription = '',
    this.odometerMiles,
    this.engineHours,
    this.status = '',
    this.allocationType = '',
    this.allocatedToDriverId,
    this.annotation = '',
    this.rejectionReason = '',
    this.pendingOver8Days = false,
  });
}

/// ملخص الأحداث غير المحددة من `GET /eld/unidentified/summary`.
class UnidentifiedSummary {
  final int totalUnclaimed;
  final int totalRejected;
  final int pendingOver8DaysCount;
  final bool complianceAlertActive;

  const UnidentifiedSummary({
    this.totalUnclaimed = 0,
    this.totalRejected = 0,
    this.pendingOver8DaysCount = 0,
    this.complianceAlertActive = false,
  });

  int get total => totalUnclaimed + totalRejected;
}

/// نتائج إحصائيات الأحداث غير المحددة (SRS 11.2 & SRS 11.6).
class UnidentifiedStats {
  final int total;
  final int unclaimed;
  final int rejected;
  final int pendingOver8Days;
  final bool complianceAlertActive;
  final bool available;

  const UnidentifiedStats({
    required this.total,
    required this.unclaimed,
    required this.rejected,
    required this.pendingOver8Days,
    required this.complianceAlertActive,
    this.available = true,
  });

  static const UnidentifiedStats unavailable = UnidentifiedStats(
    total: 0,
    unclaimed: 0,
    rejected: 0,
    pendingOver8Days: 0,
    complianceAlertActive: false,
    available: false,
  );
}

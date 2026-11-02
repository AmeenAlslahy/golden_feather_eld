import '../entities/unidentified_event.dart';

/// Builds the counters displayed by the screen from the server summary.
UnidentifiedStats statsFromSummary(UnidentifiedSummary? summary) {
  if (summary == null) return UnidentifiedStats.unavailable;
  return UnidentifiedStats(
    total: summary.total,
    unclaimed: summary.totalUnclaimed,
    rejected: summary.totalRejected,
    pendingOver8Days: summary.pendingOver8DaysCount,
    complianceAlertActive: summary.complianceAlertActive,
  );
}

/// تصفية الأحداث بالتاريخ محلياً (SRS 11.2).
List<UnidentifiedEvent> filterUnidentifiedEventsByDate(
  List<UnidentifiedEvent> items,
  DateTime? day,
) {
  if (day == null) return items;
  return items.where((item) {
    final raw = item.startTime;
    final when = raw.isEmpty ? null : DateTime.tryParse(raw)?.toLocal();
    return when != null &&
        when.year == day.year &&
        when.month == day.month &&
        when.day == day.day;
  }).toList();
}

/// تصفية الأحداث بالمركبة الحالية محلياً.
///
/// The Swagger contract does not document a vehicle filter key inside the
/// `filters` array, so the vehicle is matched against documented response
/// fields (`deviceId`, then VIN, then vehicle name).
List<UnidentifiedEvent> filterUnidentifiedEventsByVehicle(
  List<UnidentifiedEvent> items, {
  int? deviceId,
  String? vin,
  String? vehicleName,
}) {
  final hasVin = vin != null && vin.trim().isNotEmpty;
  final hasName = vehicleName != null && vehicleName.trim().isNotEmpty;
  if (deviceId == null && !hasVin && !hasName) return items;

  return items.where((item) {
    if (deviceId != null && item.deviceId != null) {
      return item.deviceId == deviceId;
    }
    if (hasVin && item.vehicleVin.isNotEmpty) {
      return item.vehicleVin.toLowerCase() == vin.trim().toLowerCase();
    }
    if (hasName && item.vehicleName.isNotEmpty) {
      return item.vehicleName.toLowerCase() == vehicleName.trim().toLowerCase();
    }
    return false;
  }).toList();
}

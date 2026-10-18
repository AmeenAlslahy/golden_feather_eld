import 'package:equatable/equatable.dart';

/// Snapshot للبيانات المحفوظة لنموذج اليوم في الخادم.
///
/// لا يحتوي على بيانات الجلسة الحية (Live Session).
class DailyFormData extends Equatable {
  /// معرّف المركبة الرقمي من `vehicle.id` في عقد النموذج — يُستخدم كـ
  /// `vehicleId` عند الحفظ (احتياط: [vehicleUniqueId] النصي).
  final int? vehicleId;
  final String? vehicleUniqueId;
  final String? vehicleName;
  final int? coDriverId;
  final String? coDriverName;
  final List<String> trailers;
  final List<String> shippingDocuments;

  const DailyFormData({
    this.vehicleId,
    this.vehicleUniqueId,
    this.vehicleName,
    this.coDriverId,
    this.coDriverName,
    this.trailers = const [],
    this.shippingDocuments = const [],
  });

  @override
  List<Object?> get props => [
    vehicleId,
    vehicleUniqueId,
    vehicleName,
    coDriverId,
    coDriverName,
    trailers,
    shippingDocuments,
  ];
}

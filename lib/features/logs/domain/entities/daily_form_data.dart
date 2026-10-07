import 'package:equatable/equatable.dart';

/// Snapshot للبيانات المحفوظة لنموذج اليوم في الخادم.
///
/// لا يحتوي على بيانات الجلسة الحية (Live Session).
class DailyFormData extends Equatable {
  final String? vehicleUniqueId;
  final String? vehicleName;
  final int? coDriverId;
  final String? coDriverName;
  final List<String> trailers;
  final List<String> shippingDocuments;

  const DailyFormData({
    this.vehicleUniqueId,
    this.vehicleName,
    this.coDriverId,
    this.coDriverName,
    this.trailers = const [],
    this.shippingDocuments = const [],
  });

  @override
  List<Object?> get props => [
    vehicleUniqueId,
    vehicleName,
    coDriverId,
    coDriverName,
    trailers,
    shippingDocuments,
  ];
}

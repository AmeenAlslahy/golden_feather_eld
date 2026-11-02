import 'package:equatable/equatable.dart';

/// Command لتحديث بيانات نموذج اليوم في الخادم.
///
/// يمثل رغبة المستخدم في الحفظ، ويجب أن يحتوي على البيانات الكاملة
/// والصالحة للنموذج المطلوب حفظه.
class DailyFormUpdate extends Equatable {
  /// معرّف المركبة النصي (uniqueId)
  final String vehicleUniqueId;

  /// معرّف المركبة الرقمي (vehicleId) وفق OAS 3.0 / Swagger PUT /form
  final int? vehicleId;

  final int? coDriverId;
  final List<String> trailers;
  final List<String> shippingDocuments;

  /// ملاحظات السائق على النموذج (`notes` في الوثيقة).
  final String? notes;

  const DailyFormUpdate({
    required this.vehicleUniqueId,
    this.vehicleId,
    this.coDriverId,
    required this.trailers,
    required this.shippingDocuments,
    this.notes,
  });

  @override
  List<Object?> get props => [
    vehicleUniqueId,
    vehicleId,
    coDriverId,
    trailers,
    shippingDocuments,
    notes,
  ];
}

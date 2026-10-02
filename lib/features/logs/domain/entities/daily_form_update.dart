import 'package:equatable/equatable.dart';

/// Command لتحديث بيانات نموذج اليوم في الخادم.
///
/// يمثل رغبة المستخدم في الحفظ، ويجب أن يحتوي على البيانات الكاملة
/// والصالحة للنموذج المطلوب حفظه.
class DailyFormUpdate extends Equatable {
  final String vehicleUniqueId;
  final int? coDriverId;
  final List<String> trailers;
  final List<String> shippingDocuments;

  const DailyFormUpdate({
    required this.vehicleUniqueId,
    this.coDriverId,
    required this.trailers,
    required this.shippingDocuments,
  });

  @override
  List<Object?> get props => [
    vehicleUniqueId,
    coDriverId,
    trailers,
    shippingDocuments,
  ];
}

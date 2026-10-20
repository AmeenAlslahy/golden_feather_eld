import 'package:equatable/equatable.dart';

/// Command لتحديث بيانات نموذج اليوم في الخادم.
///
/// يمثل رغبة المستخدم في الحفظ، ويجب أن يحتوي على البيانات الكاملة
/// والصالحة للنموذج المطلوب حفظه.
class DailyFormUpdate extends Equatable {
  /// معرّف المركبة النصي (uniqueId) — الحقل الوحيد المقبول في العقد
  /// الحالي للخادم؛ المعرّف الرقمي `vehicleId` مرفوض دائماً (400) حتى
  /// عندما يكون صحيحاً، فلا يُرسل ولا يُشتق.
  final String vehicleUniqueId;
  final int? coDriverId;
  final List<String> trailers;
  final List<String> shippingDocuments;

  /// ملاحظات السائق على النموذج (`notes` في الوثيقة).
  final String? notes;

  const DailyFormUpdate({
    required this.vehicleUniqueId,
    this.coDriverId,
    required this.trailers,
    required this.shippingDocuments,
    this.notes,
  });

  @override
  List<Object?> get props => [
    vehicleUniqueId,
    coDriverId,
    trailers,
    shippingDocuments,
    notes,
  ];
}

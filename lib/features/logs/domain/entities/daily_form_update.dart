import 'package:equatable/equatable.dart';

/// Command لتحديث بيانات نموذج اليوم في الخادم.
///
/// يمثل رغبة المستخدم في الحفظ، ويجب أن يحتوي على البيانات الكاملة
/// والصالحة للنموذج المطلوب حفظه.
class DailyFormUpdate extends Equatable {
  /// معرّف المركبة الرقمي (`vehicleId` في وثيقة الـ API) عندما تكون
  /// المركبة مختارة من قائمة الشركة كائناً كاملاً.
  final int? vehicleId;

  /// معرّف المركبة النصي (uniqueId) — احتياطي متوافق للبيانات القديمة،
  /// ويُستخدم أيضاً حين لا يتوفر [vehicleId].
  final String vehicleUniqueId;
  final int? coDriverId;
  final List<String> trailers;
  final List<String> shippingDocuments;

  /// ملاحظات السائق على النموذج (`notes` في الوثيقة).
  final String? notes;

  const DailyFormUpdate({
    this.vehicleId,
    required this.vehicleUniqueId,
    this.coDriverId,
    required this.trailers,
    required this.shippingDocuments,
    this.notes,
  });

  @override
  List<Object?> get props => [
    vehicleId,
    vehicleUniqueId,
    coDriverId,
    trailers,
    shippingDocuments,
    notes,
  ];
}

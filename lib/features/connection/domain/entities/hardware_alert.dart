/// تنبيه عطل/تشخيص جهاز (SRS 3.7) — كيان نقي بلا JSON: التحليل من الردّ
/// يتم في طبقة العرض/البيانات لا هنا.
class HardwareAlert {
  final String id;
  final String type;
  final String message;
  final DateTime? timestamp;

  const HardwareAlert({
    required this.id,
    required this.type,
    required this.message,
    this.timestamp,
  });
}

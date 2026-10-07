/// منسق المدد الموحد — كان مكرراً في `hos_indicators_card` و
/// `main_circular_timer` (باختلاف معالجة السالب فقط).
abstract final class DurationFormat {
  /// `HH:MM` مع إشارة سالب اختيارية (المؤقت الدائري قد يجاوز الحد فيصبح
  /// المتبقي سالباً).
  static String hhMm(Duration d, {bool signed = false}) {
    final negative = signed && d.isNegative;
    final abs = d.abs();
    final hours = abs.inHours;
    final minutes = abs.inMinutes.remainder(60);
    final sign = negative ? '-' : '';
    return '$sign${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}';
  }

  /// تنسيق الساعات العشرية (مثل 08.50) لجدول الملخص الأسبوعي
  static String decimalHours(Duration d) {
    final hours = d.inMinutes / 60.0;
    return hours.abs().toStringAsFixed(2).padLeft(5, '0');
  }
}

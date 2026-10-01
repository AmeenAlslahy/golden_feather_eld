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
}

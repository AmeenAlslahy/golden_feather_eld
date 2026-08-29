/// أنواع الفترات في HOS
enum HosPeriodType {
  drive('قيادة', 'Drive'),
  stop('توقف', 'Stop'),
  rest('راحة طويلة', 'Rest'),
  breakPeriod('استراحة قصيرة', 'Break'),
  gap('فجوة بيانات', 'Gap');

  final String arabicName;
  final String englishName;
  const HosPeriodType(this.arabicName, this.englishName);
}

/// نموذج فترة HOS
class HosPeriod {
  final HosPeriodType type;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final double? distanceKm;

  const HosPeriod({
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.duration,
    this.distanceKm,
  });

  double get durationHours => duration.inMinutes / 60.0;
}

/// مصنف فترات HOS
class HosPeriodClassifier {
  static const double speedThreshold = 8.0; // كم/س
  static const Duration longRestThreshold = Duration(hours: 3);
  static const Duration dataGapThreshold = Duration(minutes: 5);

  /// تصنيف فترة بناءً على السرعة والمدة
  static HosPeriodType classify({
    required double avgSpeed,
    required Duration duration,
    required bool hasDataGap,
  }) {
    if (hasDataGap) return HosPeriodType.gap;
    if (avgSpeed > speedThreshold) return HosPeriodType.drive;
    if (duration >= longRestThreshold) return HosPeriodType.rest;
    if (duration < longRestThreshold && avgSpeed <= speedThreshold) {
      return HosPeriodType.breakPeriod;
    }
    return HosPeriodType.stop;
  }


}

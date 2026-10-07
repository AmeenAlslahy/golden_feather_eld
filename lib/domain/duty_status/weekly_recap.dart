import 'package:freezed_annotation/freezed_annotation.dart';

import 'status_dashboard.dart' show CycleRule;

part 'weekly_recap.freezed.dart';

/// Weekly recap data (last 7 days + cycle summary).
@freezed
abstract class WeeklyRecap with _$WeeklyRecap {
  const factory WeeklyRecap({
    required CycleRule cycleRule,
    required Duration cycleUsed,
    required Duration cycleRemaining,
    required Duration availableTomorrow,
    required List<RecapDay> days,
  }) = _WeeklyRecap;
}

/// A single day in the weekly recap.
@freezed
abstract class RecapDay with _$RecapDay {
  const factory RecapDay({
    required DateTime date,
    required String dayOfWeek,
    required Duration driving,
    required Duration onDuty,
    required Duration totalWork,
  }) = _RecapDay;
}

/// ملحقات مساعدة لبيانات الملخص الأسبوعي
extension WeeklyRecapX on WeeklyRecap {
  /// ساعات العمل المسجلة لليوم الحالي (مطابقة لتاريخ اليوم).
  Duration get todayWork {
    final now = DateTime.now();
    for (final day in days) {
      if (day.date.year == now.year &&
          day.date.month == now.month &&
          day.date.day == now.day) {
        return day.totalWork;
      }
    }
    return Duration.zero;
  }
}

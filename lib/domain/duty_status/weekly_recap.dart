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

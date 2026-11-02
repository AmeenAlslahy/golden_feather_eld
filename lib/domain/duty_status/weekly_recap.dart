import 'package:freezed_annotation/freezed_annotation.dart';

import 'status_dashboard.dart' show CycleRule;

part 'weekly_recap.freezed.dart';

/// Weekly recap data (last 7 days + cycle summary).
@freezed
abstract class WeeklyRecap with _$WeeklyRecap {
  const WeeklyRecap._();

  const factory WeeklyRecap({
    required CycleRule cycleRule,
    required Duration cycleUsed,
    required Duration cycleRemaining,
    required Duration availableTomorrow,
    required List<RecapDay> days,

    /// Structured time values distinguishing present/missing/invalid
    /// and carrying server-formatted strings: { "seconds": ..., "formatted": ... }
    RecapTimeValue? cycleUsedTime,
    RecapTimeValue? cycleRemainingTime,
    RecapTimeValue? availableTomorrowTime,
  }) = _WeeklyRecap;

  RecapTimeValue get effectiveCycleUsed =>
      cycleUsedTime ?? RecapTimeValue.present(cycleUsed);

  RecapTimeValue get effectiveCycleRemaining =>
      cycleRemainingTime ?? RecapTimeValue.present(cycleRemaining);

  RecapTimeValue get effectiveAvailableTomorrow =>
      availableTomorrowTime ?? RecapTimeValue.present(availableTomorrow);
}

/// A single day in the weekly recap.
@freezed
abstract class RecapDay with _$RecapDay {
  const RecapDay._();

  const factory RecapDay({
    required DateTime date,
    required String dayOfWeek,
    @Default(Duration.zero) Duration driving,
    @Default(Duration.zero) Duration onDuty,
    @Default(Duration.zero) Duration totalWork,

    /// Structured time values distinguishing present/missing/invalid
    /// and carrying server-formatted strings: { "seconds": ..., "formatted": ... }
    RecapTimeValue? drivingTime,
    RecapTimeValue? onDutyTime,
    RecapTimeValue? totalWorkTime,
  }) = _RecapDay;

  /// Effective driving time: returns [drivingTime] if explicitly set,
  /// otherwise constructs a present value from legacy [driving].
  RecapTimeValue get effectiveDriving =>
      drivingTime ?? RecapTimeValue.present(driving);

  /// Effective on-duty time: returns [onDutyTime] if explicitly set,
  /// otherwise constructs a present value from legacy [onDuty].
  RecapTimeValue get effectiveOnDuty =>
      onDutyTime ?? RecapTimeValue.present(onDuty);

  /// Effective total work time: returns [totalWorkTime] if explicitly set,
  /// otherwise constructs a present value from legacy [totalWork].
  RecapTimeValue get effectiveTotalWork =>
      totalWorkTime ?? RecapTimeValue.present(totalWork);

  /// Whether driving duration is explicitly missing from the backend response.
  bool get isDrivingMissing => drivingTime?.isMissing ?? false;

  /// Whether on-duty duration is explicitly missing from the backend response.
  bool get isOnDutyMissing => onDutyTime?.isMissing ?? false;

  /// Whether total work duration is explicitly missing from the backend response.
  bool get isTotalWorkMissing => totalWorkTime?.isMissing ?? false;

  /// Effective work duration for display in the recap table.
  /// Prefers [totalWork] if present and greater than zero,
  /// otherwise falls back to [onDuty] (which is sent by the server in dailyRecap).
  Duration get displayWork {
    if (totalWork > Duration.zero) return totalWork;
    if (onDuty > Duration.zero) return onDuty;
    return totalWork;
  }
}

/// Represents a structured time value for HOS recap, capturing duration,
/// server-formatted representation, and explicit presence/validity status.
///
/// Distinguishes between:
/// - Genuine zero duration (`Duration.zero`, e.g. seconds == 0)
/// - Missing duration (`null`, field absent from backend)
/// - Invalid duration (malformed string or unparseable format)
@freezed
abstract class RecapTimeValue with _$RecapTimeValue {
  const RecapTimeValue._();

  const factory RecapTimeValue({
    /// The parsed duration. Null if missing or invalid.
    Duration? duration,

    /// Raw server-formatted representation (e.g. "11h 00m" or "05:00").
    String? formatted,

    /// State distinguishing genuine value from missing or invalid.
    @Default(RecapTimeState.present) RecapTimeState state,
  }) = _RecapTimeValue;

  /// Factory for a valid, genuine duration (including Duration.zero).
  factory RecapTimeValue.present(Duration duration, {String? formatted}) =>
      RecapTimeValue(
        duration: duration,
        formatted: formatted,
        state: RecapTimeState.present,
      );

  /// Factory for an explicitly missing duration.
  factory RecapTimeValue.missing() => const RecapTimeValue(
    duration: null,
    formatted: null,
    state: RecapTimeState.missing,
  );

  /// Factory for an invalid / unparseable duration.
  factory RecapTimeValue.invalid([String? raw]) => RecapTimeValue(
    duration: null,
    formatted: raw,
    state: RecapTimeState.invalid,
  );

  /// Helper constructor to parse from the new unified API format:
  /// `{ "seconds": 39600, "formatted": "11h 00m" }`
  /// or from a primitive (int seconds, Duration, or legacy string).
  factory RecapTimeValue.fromDynamic(dynamic raw) {
    if (raw == null) return RecapTimeValue.missing();
    if (raw is Map<String, dynamic>) {
      final secondsRaw = raw['seconds'];
      final formatted = raw['formatted'] as String?;
      if (secondsRaw is num) {
        return RecapTimeValue.present(
          Duration(seconds: secondsRaw.toInt()),
          formatted: formatted,
        );
      }
      return RecapTimeValue.invalid(formatted ?? raw.toString());
    }
    if (raw is num) {
      return RecapTimeValue.present(Duration(seconds: raw.toInt()));
    }
    if (raw is Duration) {
      return RecapTimeValue.present(raw);
    }
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return RecapTimeValue.missing();
      final parts = trimmed.split(':');
      if (parts.length >= 2 && parts.length <= 3) {
        final hours = int.tryParse(parts[0]);
        final minutes = int.tryParse(parts[1]);
        final seconds = parts.length == 3 ? int.tryParse(parts[2]) : 0;
        if (hours != null && minutes != null && seconds != null) {
          return RecapTimeValue.present(
            Duration(hours: hours, minutes: minutes, seconds: seconds),
            formatted: trimmed,
          );
        }
      }
      return RecapTimeValue.invalid(trimmed);
    }
    return RecapTimeValue.invalid(raw.toString());
  }

  /// Whether this represents a genuine, valid duration.
  bool get isPresent => state == RecapTimeState.present && duration != null;

  /// Whether this duration is explicitly missing.
  bool get isMissing => state == RecapTimeState.missing;

  /// Whether this duration is invalid/malformed.
  bool get isInvalid => state == RecapTimeState.invalid;

  /// Whether this duration is a genuine zero.
  bool get isZero => isPresent && duration == Duration.zero;

  /// Safe accessor for duration. Returns [duration] if present, or [fallback].
  Duration valueOr(Duration fallback) => duration ?? fallback;
}

enum RecapTimeState {
  /// Genuine, valid duration value (including real zero: Duration.zero).
  present,

  /// Field was not present in the backend response.
  missing,

  /// Field was present in the response but was invalid / unparseable.
  invalid,
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
        return day.displayWork;
      }
    }
    return Duration.zero;
  }
}

import 'package:flutter/material.dart';

/// App-wide time formatting utilities to ensure consistency
/// and avoid scattered `TimeOfDay` or `DateFormat` usage.
class TimeFormatter {
  /// Formats a DateTime to a 12-hour format string: `hh:mm AM/PM`.
  static String formatTime12Hour(DateTime time) {
    final h24 = time.hour;
    final h12 = h24 > 12 ? h24 - 12 : (h24 == 0 ? 12 : h24);
    final h = h12.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final period = h24 < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  /// Formats a DateTime with its timezone: `hh:mm AM/PM TZN`.
  static String formatTimeWithZone(DateTime time) {
    final baseTime = formatTime12Hour(time);
    final name = time.timeZoneName.trim();
    if (name.isEmpty) return baseTime;
    final short = name.length >= 3 ? name.substring(0, 3) : name;
    return '$baseTime ${short.toUpperCase()}';
  }

  /// Formats the current time (often needed for new logs).
  static String formatCurrentTime12Hour(DateTime time) {
    final h24 = time.hour;
    final h12 = h24 > 12 ? h24 - 12 : (h24 == 0 ? 12 : h24);
    final hStr = h12.toString().padLeft(2, '0');
    final mStr = time.minute.toString().padLeft(2, '0');
    final sStr = time.second.toString().padLeft(2, '0');
    final period = h24 < 12 ? 'AM' : 'PM';
    return '$hStr:$mStr:$sStr $period';
  }

  /// Formats a TimeOfDay to a 12-hour format string: `hh:mm AM/PM`.
  static String formatTimeOfDay12Hour(TimeOfDay time) {
    final h24 = time.hour;
    final h12 = h24 > 12 ? h24 - 12 : (h24 == 0 ? 12 : h24);
    final h = h12.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final period = h24 < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}

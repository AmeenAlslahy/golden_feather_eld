import 'package:equatable/equatable.dart';

/// كيان السجل اليومي
class DailyLog extends Equatable {
  final String id;
  final DateTime date;
  final double totalDrivingHours;
  final bool isFormComplete;
  final bool isCertified;
  final List<LogEvent> events;

  const DailyLog({
    required this.id,
    required this.date,
    required this.totalDrivingHours,
    required this.isFormComplete,
    required this.isCertified,
    this.events = const [],
  });

  DailyLog copyWith({
    String? id,
    DateTime? date,
    double? totalDrivingHours,
    bool? isFormComplete,
    bool? isCertified,
    List<LogEvent>? events,
  }) {
    return DailyLog(
      id: id ?? this.id,
      date: date ?? this.date,
      totalDrivingHours: totalDrivingHours ?? this.totalDrivingHours,
      isFormComplete: isFormComplete ?? this.isFormComplete,
      isCertified: isCertified ?? this.isCertified,
      events: events ?? this.events,
    );
  }

  String get dayName {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    }
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
  }

  String get formattedDate {
    return '$dayName - ${[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][date.month - 1]} ${date.day}${_ordinal(date.day)}';
  }

  String _ordinal(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  @override
  List<Object?> get props =>
      [id, date, totalDrivingHours, isFormComplete, isCertified, events];
}

/// كيان حدث في السجل
class LogEvent extends Equatable {
  final String id;
  final String status; // OFF, SB, D, ON
  final String statusArabic;
  final DateTime startTime;
  final Duration duration;
  final String location;
  final double? odometer;
  final double? engineHours;
  final bool isExpanded; // للـ UI

  const LogEvent({
    required this.id,
    required this.status,
    required this.statusArabic,
    required this.startTime,
    required this.duration,
    required this.location,
    this.odometer,
    this.engineHours,
    this.isExpanded = false,
  });

  String get formattedStartTime {
    final h = startTime.hour.toString().padLeft(2, '0');
    final m = startTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  LogEvent copyWith({bool? isExpanded}) {
    return LogEvent(
      id: id,
      status: status,
      statusArabic: statusArabic,
      startTime: startTime,
      duration: duration,
      location: location,
      odometer: odometer,
      engineHours: engineHours,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  @override
  List<Object?> get props =>
      [id, status, startTime, duration, location, isExpanded];
}

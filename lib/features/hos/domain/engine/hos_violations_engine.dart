import 'dart:async';

import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';

import '../../../../core/config/hos_configuration.dart';
import '../../../../core/time/trusted_time_provider.dart';
import '../../../../core/utils/logger.dart';
// ARCH-CRIT-01 fix: Use Domain port instead of Data DataSource
import '../ports/hos_storage_port.dart';
import 'tracking/duty_status_tracker.dart';

class HosViolationsEngine {
  final DutyStatusTracker _tracker;
  final HosStoragePort _localDb;
  final HosConfiguration _config;
  final TrustedTimeProvider _timeProvider;

  final List<HosViolation> _violations = [];
  Timer? _timer;

  HosViolationsEngine(
      this._tracker, this._localDb, this._config, this._timeProvider) {
    _startMonitoring();
  }

  List<HosViolation> get violations => List.unmodifiable(_violations);
  bool get hasViolations => _violations.isNotEmpty;

  void _startMonitoring() {
    // نفحص الانتهاكات كل دقيقة
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _evaluateCurrentState();
    });
  }

  void _evaluateCurrentState() {
    final timeResult = _timeProvider.currentTime;
    if (timeResult is! TrustedTimeAvailable) {
      // Cannot reliably check violations if time is unavailable
      return;
    }
    final now = timeResult.utc;

    final todayStats = _tracker.getTodayStats();
    final weekStats = _tracker.getWeekStats();

    final drivingHoursToday = todayStats['driving'] ?? 0.0;
    final workHoursToday =
        (todayStats['driving'] ?? 0.0) + (todayStats['on_duty'] ?? 0.0);
    final restHoursToday =
        (todayStats['off_duty'] ?? 0.0) + (todayStats['sleeper'] ?? 0.0);
    final drivingHoursWeek = weekStats['driving'] ?? 0.0;

    final consecutiveDays = _calculateConsecutiveDays();
    final hasBreak = _has30MinBreak(now);
    final hasWeeklyRestart = _has34HourRestart(now);

    checkAll(
      drivingHoursToday: drivingHoursToday,
      workHoursToday: workHoursToday,
      restHoursToday: restHoursToday,
      drivingHoursWeek: drivingHoursWeek,
      consecutiveDays: consecutiveDays,
      hasBreak: hasBreak,
      hasWeeklyRestart: hasWeeklyRestart,
      now: now,
    );
  }

  int _calculateConsecutiveDays() {
    final uniqueDays = <String>{};
    for (final p in _tracker.periods) {
      if (p.status == 'driving' || p.status == 'on_duty') {
        uniqueDays
            .add('${p.startTime.year}-${p.startTime.month}-${p.startTime.day}');
      }
    }
    return uniqueDays.length;
  }

  bool _has30MinBreak(DateTime now) {
    final todayStart = DateTime(now.year, now.month, now.day);
    for (final p in _tracker.periods) {
      if (p.startTime.isAfter(todayStart) &&
          (p.status == 'off_duty' || p.status == 'sleeper_berth')) {
        if (p.duration.inMinutes >= 30) {
          return true;
        }
      }
    }
    return false;
  }

  bool _has34HourRestart(DateTime now) {
    final weekStart = now.subtract(const Duration(days: 7));
    for (final p in _tracker.periods) {
      if (p.startTime.isAfter(weekStart) &&
          (p.status == 'off_duty' || p.status == 'sleeper_berth')) {
        if (p.duration.inHours >= 34) {
          return true;
        }
      }
    }
    return false;
  }

  /// فحص جميع الانتهاكات
  List<HosViolation> checkAll({
    required double drivingHoursToday,
    required double workHoursToday,
    required double restHoursToday,
    required double drivingHoursWeek,
    required int consecutiveDays,
    required bool hasBreak,
    required bool hasWeeklyRestart,
    required DateTime now,
  }) {
    _violations.clear();

    if (drivingHoursToday > 11) {
      _addViolation(
        type: HosViolationType.dailyDrivingExceeded,
        level: ViolationLevel.high,
        message:
            'Daily driving limit exceeded: ${drivingHoursToday.toStringAsFixed(1)}h / 11h',
        now: now,
        details: {'actual': drivingHoursToday, 'limit': 11},
      );
    }

    if (workHoursToday > 14) {
      _addViolation(
        type: HosViolationType.dailyWorkExceeded,
        level: ViolationLevel.high,
        message:
            'Daily work limit exceeded: ${workHoursToday.toStringAsFixed(1)}h / 14h',
        now: now,
        details: {'actual': workHoursToday, 'limit': 14},
      );
    }

    if (restHoursToday < 10 && drivingHoursToday > 0) {
      _addViolation(
        type: HosViolationType.dailyRestInsufficient,
        level: ViolationLevel.medium,
        message:
            'Insufficient daily rest: ${restHoursToday.toStringAsFixed(1)}h / 10h',
        now: now,
        details: {'actual': restHoursToday, 'required': 10},
      );
    }

    if (drivingHoursWeek > _config.cycleLimitHours) {
      _addViolation(
        type: HosViolationType.weeklyDrivingExceeded,
        level: ViolationLevel.critical,
        message:
            'Weekly driving limit exceeded: ${drivingHoursWeek.toStringAsFixed(1)}h / ${_config.cycleLimitHours}h',
        now: now,
        details: {'actual': drivingHoursWeek, 'limit': _config.cycleLimitHours},
      );
    }

    if (!hasBreak && drivingHoursToday > 8) {
      _addViolation(
        type: HosViolationType.no30MinBreakAfter8h,
        level: ViolationLevel.medium,
        message: 'No 30-minute break after 8 hours of driving',
        now: now,
        details: {'driving_hours': drivingHoursToday},
      );
    }

    if (consecutiveDays > 7) {
      _addViolation(
        type: HosViolationType.consecutiveDaysExceeded,
        level: ViolationLevel.medium,
        message:
            'Consecutive work days exceeded: $consecutiveDays days / 7 days',
        now: now,
        details: {'actual': consecutiveDays, 'limit': 7},
      );
    }

    if (!hasWeeklyRestart && drivingHoursWeek > 60) {
      _addViolation(
        type: HosViolationType.weeklyRestInsufficient,
        level: ViolationLevel.critical,
        message: 'Insufficient weekly rest (34-hour restart required)',
        now: now,
        details: {'required': 34},
      );
    }

    return _violations;
  }

  void _addViolation({
    required HosViolationType type,
    required ViolationLevel level,
    required String message,
    required DateTime now,
    Map<String, dynamic>? details,
  }) {
    // Check if we already added this violation recently to prevent spamming DB
    final isDuplicate = _violations.any(
        (v) => v.type == type && now.difference(v.timestamp).inMinutes < 60);
    if (isDuplicate) return;

    final violation = HosViolation(
      type: type,
      level: level,
      message: message,
      timestamp: now,
      details: details,
    );

    _violations.add(violation);
    AppLogger.warning('⚠️ HOS Violation: $message');

    // حفظ في قاعدة البيانات المحلية
    _localDb.saveViolation(violation.toJson()).then((success) {
      if (success) {
        AppLogger.info('HOS Violation saved successfully');
      } else {
        AppLogger.error('Failed to save HOS violation');
      }
    }).catchError((e) {
      AppLogger.error('Failed to save HOS violation', e);
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}

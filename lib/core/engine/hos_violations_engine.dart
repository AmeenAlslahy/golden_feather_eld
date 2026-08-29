import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/logger.dart';
import 'hos_calculator.dart';
import 'tracking/duty_status_tracker.dart';
import '../services/local_database_service.dart';




/// محرك اكتشاف انتهاكات HOS
import 'hos_models.dart';

class HosViolationsEngine {
  final DutyStatusTracker _tracker;
  final LocalDatabaseService _localDb;
  
  final List<HosViolation> _violations = [];
  Timer? _timer;

  HosViolationsEngine(this._tracker, this._localDb) {
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
    final todayStats = _tracker.getTodayStats();
    final weekStats = _tracker.getWeekStats();

    final drivingHoursToday = todayStats['driving'] ?? 0.0;
    final workHoursToday = (todayStats['driving'] ?? 0.0) + (todayStats['on_duty'] ?? 0.0);
    final restHoursToday = (todayStats['off_duty'] ?? 0.0) + (todayStats['sleeper'] ?? 0.0);
    final drivingHoursWeek = weekStats['driving'] ?? 0.0;

    final consecutiveDays = _calculateConsecutiveDays();
    final hasBreak = _has30MinBreak();
    final hasWeeklyRestart = _has34HourRestart();

    checkAll(
      drivingHoursToday: drivingHoursToday,
      workHoursToday: workHoursToday,
      restHoursToday: restHoursToday,
      drivingHoursWeek: drivingHoursWeek,
      consecutiveDays: consecutiveDays,
      hasBreak: hasBreak,
      hasWeeklyRestart: hasWeeklyRestart,
    );
  }

  int _calculateConsecutiveDays() {
    final uniqueDays = <String>{};
    for (final p in _tracker.periods) {
      if (p.status == 'driving' || p.status == 'on_duty') {
        uniqueDays.add('${p.startTime.year}-${p.startTime.month}-${p.startTime.day}');
      }
    }
    return uniqueDays.length;
  }

  bool _has30MinBreak() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    for (final p in _tracker.periods) {
      if (p.startTime.isAfter(todayStart) && (p.status == 'off_duty' || p.status == 'sleeper_berth')) {
        if (p.duration.inMinutes >= 30) {
          return true;
        }
      }
    }
    return false;
  }

  bool _has34HourRestart() {
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));
    for (final p in _tracker.periods) {
      if (p.startTime.isAfter(weekStart) && (p.status == 'off_duty' || p.status == 'sleeper_berth')) {
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
  }) {
    _violations.clear();

    if (drivingHoursToday > 11) {
      _addViolation(
        type: HosViolationType.dailyDrivingExceeded,
        level: ViolationLevel.high,
        message: 'Daily driving limit exceeded: ${drivingHoursToday.toStringAsFixed(1)}h / 11h',
        arabicMessage: 'تجاوز حد القيادة اليومي: ${drivingHoursToday.toStringAsFixed(1)} ساعة / 11 ساعة',
        details: {'actual': drivingHoursToday, 'limit': 11},
      );
    }

    if (workHoursToday > 14) {
      _addViolation(
        type: HosViolationType.dailyWorkExceeded,
        level: ViolationLevel.high,
        message: 'Daily work limit exceeded: ${workHoursToday.toStringAsFixed(1)}h / 14h',
        arabicMessage: 'تجاوز حد العمل اليومي: ${workHoursToday.toStringAsFixed(1)} ساعة / 14 ساعة',
        details: {'actual': workHoursToday, 'limit': 14},
      );
    }

    if (restHoursToday < 10 && drivingHoursToday > 0) {
      _addViolation(
        type: HosViolationType.dailyRestInsufficient,
        level: ViolationLevel.medium,
        message: 'Insufficient daily rest: ${restHoursToday.toStringAsFixed(1)}h / 10h',
        arabicMessage: 'عدم كفاية الراحة اليومية: ${restHoursToday.toStringAsFixed(1)} ساعة / 10 ساعات',
        details: {'actual': restHoursToday, 'required': 10},
      );
    }

    if (drivingHoursWeek > HosCalculator.activeMaxCycleHours) {
      _addViolation(
        type: HosViolationType.weeklyDrivingExceeded,
        level: ViolationLevel.critical,
        message: 'Weekly driving limit exceeded: ${drivingHoursWeek.toStringAsFixed(1)}h / ${HosCalculator.activeMaxCycleHours}h',
        arabicMessage: 'تجاوز حد القيادة الأسبوعي: ${drivingHoursWeek.toStringAsFixed(1)} ساعة / ${HosCalculator.activeMaxCycleHours} ساعة',
        details: {'actual': drivingHoursWeek, 'limit': HosCalculator.activeMaxCycleHours},
      );
    }

    if (!hasBreak && drivingHoursToday > 8) {
      _addViolation(
        type: HosViolationType.no30MinBreakAfter8h,
        level: ViolationLevel.medium,
        message: 'No 30-minute break after 8 hours of driving',
        arabicMessage: 'عدم أخذ استراحة 30 دقيقة بعد 8 ساعات قيادة',
        details: {'driving_hours': drivingHoursToday},
      );
    }

    if (consecutiveDays > 7) {
      _addViolation(
        type: HosViolationType.consecutiveDaysExceeded,
        level: ViolationLevel.medium,
        message: 'Consecutive work days exceeded: $consecutiveDays days / 7 days',
        arabicMessage: 'تجاوز الأيام المتتالية: $consecutiveDays أيام / 7 أيام',
        details: {'actual': consecutiveDays, 'limit': 7},
      );
    }

    if (!hasWeeklyRestart && drivingHoursWeek > 60) {
      _addViolation(
        type: HosViolationType.weeklyRestInsufficient,
        level: ViolationLevel.critical,
        message: 'Insufficient weekly rest (34-hour restart required)',
        arabicMessage: 'عدم كفاية الراحة الأسبوعية (يتطلب 34 ساعة راحة متتالية)',
        details: {'required': 34},
      );
    }

    return _violations;
  }

  void _addViolation({
    required HosViolationType type,
    required ViolationLevel level,
    required String message,
    required String arabicMessage,
    Map<String, dynamic>? details,
  }) {
    // Check if we already added this violation recently to prevent spamming DB
    final isDuplicate = _violations.any((v) => v.type == type && DateTime.now().difference(v.timestamp).inMinutes < 60);
    if (isDuplicate) return;

    final violation = HosViolation(
      type: type,
      level: level,
      message: message,
      arabicMessage: arabicMessage,
      timestamp: DateTime.now(),
      details: details,
    );
    
    _violations.add(violation);
    AppLogger.warning('⚠️ HOS Violation: $message');
    
    // حفظ في قاعدة البيانات المحلية
    _localDb.saveViolation(violation.toJson()).then((result) {
      result.match(
        (failure) => AppLogger.error('Failed to save HOS violation', failure.message),
        (success) => AppLogger.info('HOS Violation saved successfully'),
      );
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// مزود محرك الانتهاكات
final hosViolationsEngineProvider = Provider<HosViolationsEngine>((ref) {
  final tracker = ref.watch(dutyStatusTrackerProvider);
  final db = ref.watch(localDatabaseServiceProvider);
  final engine = HosViolationsEngine(tracker, db);
  ref.onDispose(() {
    engine.dispose();
  });
  return engine;
});

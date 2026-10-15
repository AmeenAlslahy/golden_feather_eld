import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'dart:async';

import '../../../../core/utils/logger.dart';
import '../../../../core/time/trusted_time_provider.dart';
import '../../../../domain/duty_status/duty_status_code.dart';

/// آلة حالات ساعات الخدمة
class HosStateMachine {
  DutyStatus _currentStatus = DutyStatus.offDuty;
  DateTime _shiftStartTime = DateTime.utc(1970);
  double _accumulatedDrivingHours = 0.0;
  double _accumulatedCycleHours = 0.0;
  DateTime? _drivingSessionStartTime;
  DateTime? _onDutySessionStartTime;
  DateTime? _lastWeeklyRestartAt;

  /// بداية آخر فترة عمل مستمر (قبل，她的	break الحالي).
  DateTime? _currentDrivingRunStart;
  DateTime? _pendingBreakCandidateStart;

  /// القيادة المتراكمة منذ آخر استراحة مؤهلة.
  double _accumulatedDrivingSinceBreak = 0.0;

  final List<StatusTransition> _transitions = [];
  Timer? _drivingTimer;
  final TrustedTimeProvider _timeProvider;

/// الحد الأدنى للاستراحة المؤهلة — من `HosConfiguration.breakDurationMinutes`.
///
/// ⚠️ كان **ثابتاً 30 دقيقة مكتوبة يدوياً** والتعليق يقول إنه من الإعدادات.
/// فأي نظام بدّل مدتها (بعض ولايات أخرى) لبقي
/// المحرك يحسب على 30 ويُصنّف استراحة مؤهلة لم تكن كذلك.
///
/// الافتراضي يبقى 30 دقيقة (49 CFR 395.3(a)(3)(ii)) فسلوك غير محدَّد
/// لا يتغيّر.
final Duration _breakDuration;

HosStateMachine(this._timeProvider, {Duration? breakDuration})
    : _breakDuration = breakDuration ?? const Duration(minutes: 30) {
  final trusted = _trustedNow();
  if (trusted != null) _shiftStartTime = trusted;
}

  /// Legal timestamps only. Wall-clock time is never used as a duty stamp.
  DateTime? _trustedNow() {
    final timeResult = _timeProvider.currentTime;
    return timeResult is TrustedTimeAvailable ? timeResult.utc : null;
  }
  DateTime _effectiveNow() => _trustedNow() ?? DateTime.now().toUtc();

  // ========== Getters ==========

  DutyStatus get currentStatus => _currentStatus;
  DateTime get shiftStartTime => _shiftStartTime;
  DateTime? get lastWeeklyRestartAt => _lastWeeklyRestartAt;

  /// ساعات القيادة منذ آخر استراحة مؤهلة (≥30 دقيقة متصلة غير قيادة).
  ///
  /// 49 CFR 395.3(a)(3)(ii): "driving is not permitted if more than 8 hours
  /// of driving time have passed without at least a consecutive 30-minute
  /// interruption in driving status". therefore the 8-hour threshold is
  /// measured from the LAST qualifying interruption, NOT from the last weekly
  /// restart. قبل هذا كان العدّاد التراكمي العام فلا يُصفَر أبداً.
  double drivingHoursSinceBreak() {
    var total = _accumulatedDrivingSinceBreak;
    if (_currentStatus == DutyStatus.driving &&
        _drivingSessionStartTime != null) {
      final now = _effectiveNow();
      if (now.isAfter(_drivingSessionStartTime!)) {
        total += now.difference(_drivingSessionStartTime!).inSeconds / 3600.0;
      }
    }
    return total;
  }

  double get totalDrivingHours {
    if (_currentStatus == DutyStatus.driving && _drivingSessionStartTime != null) {
      final now = _effectiveNow();
      if (now.isAfter(_drivingSessionStartTime!)) {
        final session = now.difference(_drivingSessionStartTime!).inSeconds / 3600.0;
        return _accumulatedDrivingHours + session;
      }
    }
    return _accumulatedDrivingHours;
  }

  double get cycleHours {
    if (_currentStatus == DutyStatus.driving && _drivingSessionStartTime != null) {
      final now = _effectiveNow();
      if (now.isAfter(_drivingSessionStartTime!)) {
        final session = now.difference(_drivingSessionStartTime!).inSeconds / 3600.0;
        return _accumulatedCycleHours + session;
      }
    } else if (_currentStatus == DutyStatus.onDutyNotDriving && _onDutySessionStartTime != null) {
      final now = _effectiveNow();
      if (now.isAfter(_onDutySessionStartTime!)) {
        final session = now.difference(_onDutySessionStartTime!).inSeconds / 3600.0;
        return _accumulatedCycleHours + session;
      }
    }
    return _accumulatedCycleHours;
  }

  // ========== التحويلات ==========

  /// الانتقال إلى حالة جديدة
  void transitionTo(DutyStatus newStatus, {String? annotation}) {
    if (_currentStatus == newStatus) return;
    final now = _trustedNow();
    if (now == null) {
      AppLogger.warning(
          'Refusing duty transition: trusted time unavailable');
      return;
    }

    if (_currentStatus == DutyStatus.driving && _drivingSessionStartTime != null) {
      if (now.isAfter(_drivingSessionStartTime!)) {
        final session = now.difference(_drivingSessionStartTime!).inSeconds / 3600.0;
        _accumulatedDrivingHours += session;
        _accumulatedCycleHours += session;
      }
      _drivingSessionStartTime = null;
    }
    if (_currentStatus == DutyStatus.onDutyNotDriving && _onDutySessionStartTime != null) {
      if (now.isAfter(_onDutySessionStartTime!)) {
        final session = now.difference(_onDutySessionStartTime!).inSeconds / 3600.0;
        _accumulatedCycleHours += session;
      }
      _onDutySessionStartTime = null;
    }

    final transition = StatusTransition(
      from: _currentStatus,
      to: newStatus,
      timestamp: now,
      annotation: annotation,
    );

    _transitions.add(transition);
    _currentStatus = newStatus;

    // ♻️ منطق الاستراحة المؤهلة (30 دقيقة متصلة) — 49 CFR 395.3(a)(3)(ii).
    //
    // عند مغادرة القيادة نبدأ عدّاد فترة الراحة، وعند العودة نقيّم: إن
    // بلغت 30 دقيقة متصلة (أو زاد) صُفِّر عداد "القيادة منذ الاستراحة".
    // فترةbreaks لا ت必须是 متصلة في تطبيقنا: أي فترة غير قيادة تُقاس،
    // وهو ما يتوافق مع النص ("off-duty, sleeper berth or on-duty not
    // driving ... or a combination").
    final wasDriving = transition.from == DutyStatus.driving;
    final isDriving = newStatus == DutyStatus.driving;
    final isNonDriving =
        newStatus == DutyStatus.offDuty ||
            newStatus == DutyStatus.sleeperBerth ||
            newStatus == DutyStatus.onDutyNotDriving ||
            newStatus == DutyStatus.personalUse;

    if (wasDriving && !isDriving) {
      _pendingBreakCandidateStart = now;
      if (_currentDrivingRunStart != null) {
        final run = now.difference(_currentDrivingRunStart!);
        if (!run.isNegative) _accumulatedDrivingSinceBreak += run.inSeconds / 3600.0;
        _currentDrivingRunStart = null;
      }
    } else if (!wasDriving && isDriving) {
      final breakStart = _pendingBreakCandidateStart;
      if (breakStart != null && now.difference(breakStart) >= _breakDuration) {
        _accumulatedDrivingSinceBreak = 0.0;
      }
      _pendingBreakCandidateStart = null;
      _currentDrivingRunStart = now;
    } else if (isDriving) {
      // قيادة مستمرة — نضمن بدء计量.
      _currentDrivingRunStart ??= now;
    } else if (isNonDriving && _pendingBreakCandidateStart == null) {
      // راحة تالية بلا قيادة سابقة: نبدأ العدّاد أيضاً.
      _pendingBreakCandidateStart = now;
    }

    // بدء/إيقاف مؤقت القيادة
    if (newStatus == DutyStatus.driving) {
      _drivingSessionStartTime = now;
      _startDrivingTimer();
    } else {
      _stopDrivingTimer();
      if (newStatus == DutyStatus.onDutyNotDriving) {
        _onDutySessionStartTime = now;
      }
    }

    // إعادة تعيين نافذة العمل إذا كانت خارج الخدمة
    if (newStatus == DutyStatus.offDuty ||
        newStatus == DutyStatus.sleeperBerth) {
      // لا نعيد التعيين تلقائياً، يعتمد على مدة الراحة
    }

    AppLogger.info(
        'State transition: ${transition.from.name} → ${transition.to.name}');
  }

  /// بدء مؤقت القيادة للإشعار الدوري
  void _startDrivingTimer() {
    _drivingTimer?.cancel();
    _drivingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      // Timer acts as a periodic heartbeat for external readers
    });
  }

  /// إيقاف مؤقت القيادة
  void _stopDrivingTimer() {
    _drivingTimer?.cancel();
    _drivingTimer = null;
  }

  /// الحصول على سجل التحويلات
  List<StatusTransition> get transitions => List.unmodifiable(_transitions);

  /// إعادة تعيين
  void applyWeeklyRestart() {
    _accumulatedCycleHours = 0.0;
    _accumulatedDrivingHours = 0.0;
    _accumulatedDrivingSinceBreak = 0.0;
    _currentDrivingRunStart = _currentStatus == DutyStatus.driving
        ? _trustedNow()
        : null;
    _pendingBreakCandidateStart =
        (_currentStatus == DutyStatus.offDuty || _currentStatus == DutyStatus.sleeperBerth)
            ? _trustedNow()
            : null;
    final now = _trustedNow() ?? DateTime.utc(1970);
    _shiftStartTime = now;
    _lastWeeklyRestartAt = now;
    if (_currentStatus == DutyStatus.driving) {
      _drivingSessionStartTime = now;
    } else if (_currentStatus == DutyStatus.onDutyNotDriving) {
      _onDutySessionStartTime = now;
    }
  }

  void reset() {
    _stopDrivingTimer();
    _currentStatus = DutyStatus.offDuty;
    _shiftStartTime = _trustedNow() ?? DateTime.utc(1970);
    _accumulatedDrivingHours = 0.0;
    _accumulatedCycleHours = 0.0;
    _drivingSessionStartTime = null;
    _onDutySessionStartTime = null;
    _lastWeeklyRestartAt = null;
    _accumulatedDrivingSinceBreak = 0.0;
    _currentDrivingRunStart = null;
    _pendingBreakCandidateStart = null;
    _transitions.clear();
  }

  // ========== الاستعادة من الفترات المحفوظة محلياً ==========
  //
  // شرط "العمل أوفلاين كالأونلاين": بعد إعادة تشغيل التطبيق (أو قيود بعد
  // إقلاع بلا شبكة) يجب أن يعرف المحرك:
//  //   • حالة الخدمة الفعلية
  //   • بداية نافذة الوردية
  //   • ساعات القيادة المتراكمة والدورة
  //
  // المصدر: فترات الخدمة المحفوظة في periodsBox عبر LogLocalDataSource
  // (تُكتب عند كل تغيّر حالة في DutyStatusTracker._transitionTo).
  //
  // [periods] مرتّبة زمنياً. [cycleWindowStart] بداية نافذة الدورة (٧ أو ٨ أيام).
  void hydrateFromPeriods({
    required List<DutyPeriod> periods,
    required DateTime now,
    required Duration shiftWindow,
    Duration cycleWindow = const Duration(days: 8),
    String? currentStatusWire,
  }) {
    if (periods.isEmpty) return;

    final ordered = [...periods]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    double drivingHours = 0;
    double cycleHours = 0;
    double drivingSinceBreak = 0;
    bool sinceBreakClear = true;
    DateTime? firstDutyStart;
    DateTime? lastEventEnd;
    DutyStatus lastStatus = DutyStatus.offDuty;
    bool sawRestAfterCycleStart = false;

    // نافذة الدورة: نقتصر على الفترات داخل آخر [cycleWindow].
    final cycleStart = now.subtract(cycleWindow);

    // نافذة الوردية (14h) تُعيد نفسها بعد كل راحة مؤهلة >= 10 ساعات
    // متتالية - 49 CFR 395.3(a)(1). سابقاً كان [firstDutyStart] يأخذ أول
    // فترة عمل من كامل السجل بلا حدّ، فسائق عمل قبل ثمانية أيام كانت
    // نافذة ورديته تبدأ قبل ثمانية أيام => المتبقي 14h ناقص ثمانية أيام
    // => يُصفَّر عند الصفر = مخالفة ورقية **مُختلَقة**.
    var pendingRestGap = Duration.zero;

    for (final p in ordered) {
      final start = p.startTime;
      final end = p.endTime;
      if (end.isBefore(start)) continue; // حماية من فترات تالفة

      lastStatus = _statusFromWire(p.status);
      lastEventEnd = end;

      final isRest =
          lastStatus == DutyStatus.offDuty || lastStatus == DutyStatus.sleeperBerth;

      // راحة مؤهلة تسبق فترة العمل => ابدأ نافذة جديدة من تلك الفترة.
      if (pendingRestGap >= const Duration(hours: 10)) firstDutyStart = null;
      pendingRestGap =
          isRest ? end.difference(start) + pendingRestGap : Duration.zero;

      // نافذة الوردية تبدأ بأول فترة عمل بعد آخر راحة مؤهلة.
      if (firstDutyStart == null && !isRest) firstDutyStart = start;

      if (!end.isBefore(cycleStart)) {
        final hours = end.difference(start).inSeconds / 3600.0;
        if (lastStatus == DutyStatus.driving) {
          drivingHours += hours;
          cycleHours += hours;
          if (!sinceBreakClear) drivingSinceBreak += hours;
        } else if (lastStatus == DutyStatus.onDutyNotDriving ||
            lastStatus == DutyStatus.personalUse) {
          cycleHours += hours;
        }
        if (isRest) {
          sawRestAfterCycleStart = true;
          if (hours * 60 >= _breakDuration.inMinutes) sinceBreakClear = true;
        }
      }
    }

    if (lastEventEnd != null) {
      _currentStatus = lastStatus;
    }

    // 🔴 الحالة الحقيقية ليست حالة آخر فترة **مغلقة**.
    //
    // `DutyStatusTracker` يكتب الفترة *السابقة* عند كل انتقال، فآخر صف
    // في القرص يصف الحالة التي كان عليها السائق **قبل** الانتقال
    // الأخير — أي متأخرة بمرحلة واحدة كاملة.
    //
    // المعطي الصحيح هو `LocalStorageService.currentDutyStatus` الذي
    // يكتبه المتتبّع عند كل انتقال (بصيغة engine code: `on_duty`…).
    // فإن لم يتوفّر أو كان تالفاً نُبقي السلوك السابق (آخر فترة مغلقة).
    //
    // ⚠️ parsing **صارم** عبر `tryFromAny`: `fromAny` يرجع `offDuty` لكل
    // قيمة مجهولة، فلنستخدمه هنا لقيمة مخزّنة تالفة
    // كانت ستجبر السائق على راحة لم يطلبها.
    final resolved = DutyStatusCode.tryFromAny(currentStatusWire);
    if (resolved != null) {
      final declared = _statusFromCode(resolved);
      if (declared != _currentStatus) {
        AppLogger.info(
            '♻️ HOS hydrated status corrected: last-closed=${lastStatus.name} '
            '→ declared=${declared.name}');
      }
      _currentStatus = declared;
    } else if ((currentStatusWire ?? '').trim().isNotEmpty) {
      AppLogger.warning(
          'HOS hydration: unusable currentDutyStatus '
          '"$currentStatusWire" — keeping last closed period');
    }

    // بداية الوردية = أول عمل، أو الآن إن لم يوجد سجل (سائق جديد).
    _shiftStartTime = firstDutyStart ?? now;

    // نافذة الوردية تُنهى بـ 10 ساعات راحة متتالية (49 CFR 395.3(a)(1)):
    // إن كان السائق في راحة الآن وطوال الوقت، نبدأ نافذة جديدة.
    if (_currentStatus == DutyStatus.offDuty ||
        _currentStatus == DutyStatus.sleeperBerth) {
      final restStart = _lastDutyEndBeforeRest(ordered);
      if (restStart != null &&
          now.difference(restStart) > const Duration(hours: 10)) {
        _shiftStartTime = now;
      }
    }

    // ⚠️ لا تُصفَّر المناوبات إلا عبر إعادة التصفير الأسبوعية؛ هنا نعيد
    // بناء ما إذا كان قد حدثت فعلاً (٣٤ ساعة راحة داخل النافذة).
    if (sawRestAfterCycleStart && _longestRestIn(ordered, cycleStart) >=
        const Duration(hours: 34)) {
      _accumulatedCycleHours = 0;
      _accumulatedDrivingHours = 0;
      _shiftStartTime = now;
      _lastWeeklyRestartAt = now;
    } else {
      _accumulatedDrivingHours = drivingHours;
      _accumulatedCycleHours = cycleHours;
      _accumulatedDrivingSinceBreak = drivingSinceBreak;
      _pendingBreakCandidateStart = sinceBreakClear ? null : lastEventEnd;
      _currentDrivingRunStart =
          (_currentStatus == DutyStatus.driving && lastEventEnd != null)
              ? lastEventEnd
              : null;
    }

    if (_currentStatus == DutyStatus.driving && lastEventEnd != null) {
      _drivingSessionStartTime = lastEventEnd;
    } else if (_currentStatus == DutyStatus.onDutyNotDriving && lastEventEnd != null) {
      _onDutySessionStartTime = lastEventEnd;
    }

    // إعادة بناء سجل الانتقالات (يلزم لفحص الإعادة الأسبوعية).
    _transitions.clear();
    for (final p in ordered) {
      _transitions.add(StatusTransition(
        from: _previousStatusOf(ordered, p),
        to: _statusFromWire(p.status),
        timestamp: p.startTime,
        annotation: 'restored-from-disk',
      ));
    }

    AppLogger.info(
        '♻️ HOS hydrated from ${periods.length} period(s): '
        'status=${_currentStatus.name} '
        'driving=${_accumulatedDrivingHours.toStringAsFixed(2)}h '
        'cycle=${_accumulatedCycleHours.toStringAsFixed(2)}h '
        'shiftStart=${_shiftStartTime.toIso8601String()}');
  }

  /// تحويل رمز معروف مسبقاً إلى حالة المحرك.
  static DutyStatus _statusFromCode(DutyStatusCode code) {
    switch (code) {
      case DutyStatusCode.driving:
        return DutyStatus.driving;
      case DutyStatusCode.onDutyNotDriving:
      case DutyStatusCode.yardMove:
        return DutyStatus.onDutyNotDriving;
      case DutyStatusCode.sleeperBerth:
        return DutyStatus.sleeperBerth;
      case DutyStatusCode.personalConveyance:
        return DutyStatus.personalUse;
      case DutyStatusCode.offDuty:
        return DutyStatus.offDuty;
    }
  }

  static DutyStatus _statusFromWire(String wire) {
    switch (DutyStatusCode.fromAny(wire)) {
      case DutyStatusCode.driving:
        return DutyStatus.driving;
      case DutyStatusCode.onDutyNotDriving:
      case DutyStatusCode.yardMove:
        return DutyStatus.onDutyNotDriving;
      case DutyStatusCode.sleeperBerth:
        return DutyStatus.sleeperBerth;
      case DutyStatusCode.personalConveyance:
        return DutyStatus.personalUse;
      case DutyStatusCode.offDuty:
        return DutyStatus.offDuty;
    }
  }

  static DutyStatus _previousStatusOf(List<DutyPeriod> sorted, DutyPeriod p) {
    final i = sorted.indexOf(p);
    if (i <= 0) return DutyStatus.offDuty;
    return _statusFromWire(sorted[i - 1].status);
  }

  static DateTime? _lastDutyEndBeforeRest(List<DutyPeriod> ordered) {
    for (var i = ordered.length - 1; i >= 0; i--) {
      final s = _statusFromWire(ordered[i].status);
      if (s != DutyStatus.offDuty && s != DutyStatus.sleeperBerth) {
        return ordered[i].endTime;
      }
    }
    return null;
  }

  static Duration _longestRestIn(List<DutyPeriod> ordered, DateTime from) {
    var longest = Duration.zero;
    DateTime? restStart;
    for (final p in ordered) {
      final s = _statusFromWire(p.status);
      final isRest = s == DutyStatus.offDuty || s == DutyStatus.sleeperBerth;
      if (isRest) {
        restStart ??= p.startTime;
        final d = p.endTime.difference(restStart);
        if (d > longest) longest = d;
      } else {
        restStart = null;
      }
    }
    return longest;
  }

  void dispose() {
    _stopDrivingTimer();
  }
}

/// تحويل حالة
class StatusTransition {
  final DutyStatus from;
  final DutyStatus to;
  final DateTime timestamp;
  final String? annotation;

  const StatusTransition({
    required this.from,
    required this.to,
    required this.timestamp,
    this.annotation,
  });
}

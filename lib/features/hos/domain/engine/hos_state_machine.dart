 // ignore: unused_import

import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';

import '../../../../core/time/trusted_time_provider.dart';
import '../../../../core/utils/logger.dart';

/// آلة حالات ساعات الخدمة
class HosStateMachine {
  DutyStatus _currentStatus = DutyStatus.offDuty;
  late DateTime _shiftStartTime;
  double _accumulatedDrivingHours = 0.0;
  double _accumulatedCycleHours = 0.0;
  DateTime? _lastStatusChangeTime;

  final List<StatusTransition> _transitions = [];
  final TrustedTimeProvider _timeProvider;

  HosStateMachine(this._timeProvider) {
    _shiftStartTime = _getCurrentTime();
    _lastStatusChangeTime = _shiftStartTime;
  }

  DateTime _getCurrentTime() {
    final timeResult = _timeProvider.currentTime;
    return timeResult is TrustedTimeAvailable
        ? timeResult.utc
        : DateTime.now().toUtc();
  }

  // ========== Getters ==========

  DutyStatus get currentStatus => _currentStatus;
  DateTime get shiftStartTime => _shiftStartTime;
  
  double get totalDrivingHours {
    double current = _accumulatedDrivingHours;
    if (_currentStatus == DutyStatus.driving && _lastStatusChangeTime != null) {
      current += _getCurrentTime().difference(_lastStatusChangeTime!).inSeconds / 3600.0;
    }
    return current;
  }

  double get cycleHours {
    double current = _accumulatedCycleHours;
    if ((_currentStatus == DutyStatus.driving || _currentStatus == DutyStatus.onDutyNotDriving) && _lastStatusChangeTime != null) {
      current += _getCurrentTime().difference(_lastStatusChangeTime!).inSeconds / 3600.0;
    }
    return current;
  }

  // ========== التحويلات ==========

  /// الانتقال إلى حالة جديدة
  void transitionTo(DutyStatus newStatus, {String? annotation}) {
    if (_currentStatus == newStatus) return;

    final transitionTime = _getCurrentTime();
    
    if (_lastStatusChangeTime != null) {
      final elapsedHours = transitionTime.difference(_lastStatusChangeTime!).inSeconds / 3600.0;
      if (_currentStatus == DutyStatus.driving) {
        _accumulatedDrivingHours += elapsedHours;
      }
      if (_currentStatus == DutyStatus.driving || _currentStatus == DutyStatus.onDutyNotDriving) {
        _accumulatedCycleHours += elapsedHours;
      }
    }

    final transition = StatusTransition(
      from: _currentStatus,
      to: newStatus,
      timestamp: transitionTime,
      annotation: annotation,
    );

    _transitions.add(transition);
    _currentStatus = newStatus;
    _lastStatusChangeTime = transitionTime;

    // إعادة تعيين نافذة العمل إذا كانت خارج الخدمة
    if (newStatus == DutyStatus.offDuty ||
        newStatus == DutyStatus.sleeperBerth) {
      // لا نعيد التعيين تلقائياً، يعتمد على مدة الراحة
    }

    AppLogger.info(
        'State transition: ${transition.from.name} → ${transition.to.name}');
  }

  /// الحصول على سجل التحويلات
  List<StatusTransition> get transitions => List.unmodifiable(_transitions);

  /// إعادة تعيين
  void reset() {
    _currentStatus = DutyStatus.offDuty;
    _shiftStartTime = _getCurrentTime();
    _lastStatusChangeTime = _shiftStartTime;
    _accumulatedDrivingHours = 0.0;
    _accumulatedCycleHours = 0.0;
    _transitions.clear();
  }

  void dispose() {
    // No timers to cancel anymore
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

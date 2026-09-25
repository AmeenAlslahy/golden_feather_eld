import 'dart:async';

import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';

import '../../../../core/time/trusted_time_provider.dart';
import '../../../../core/utils/logger.dart';

/// آلة حالات ساعات الخدمة
class HosStateMachine {
  DutyStatus _currentStatus = DutyStatus.offDuty;
  DateTime _shiftStartTime = DateTime.utc(1970);
  double _totalDrivingHours = 0.0;
  double _cycleHours = 0.0;

  final List<StatusTransition> _transitions = [];
  Timer? _drivingTimer;
  final TrustedTimeProvider _timeProvider;

  HosStateMachine(this._timeProvider) {
    final trusted = _trustedNow();
    if (trusted != null) _shiftStartTime = trusted;
  }

  /// Legal timestamps only. Wall-clock time is never used as a duty stamp.
  DateTime? _trustedNow() {
    final timeResult = _timeProvider.currentTime;
    return timeResult is TrustedTimeAvailable ? timeResult.utc : null;
  }

  // ========== Getters ==========

  DutyStatus get currentStatus => _currentStatus;
  DateTime get shiftStartTime => _shiftStartTime;
  double get totalDrivingHours => _totalDrivingHours;
  double get cycleHours => _cycleHours;

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

    final transition = StatusTransition(
      from: _currentStatus,
      to: newStatus,
      timestamp: now,
      annotation: annotation,
    );

    _transitions.add(transition);
    _currentStatus = newStatus;

    // بدء/إيقاف مؤقت القيادة
    if (newStatus == DutyStatus.driving) {
      _startDrivingTimer();
    } else {
      _stopDrivingTimer();
    }

    // إعادة تعيين نافذة العمل إذا كانت خارج الخدمة
    if (newStatus == DutyStatus.offDuty ||
        newStatus == DutyStatus.sleeperBerth) {
      // لا نعيد التعيين تلقائياً، يعتمد على مدة الراحة
    }

    AppLogger.info(
        'State transition: ${transition.from.name} → ${transition.to.name}');
  }

  /// بدء مؤقت القيادة
  void _startDrivingTimer() {
    _drivingTimer?.cancel();
    _drivingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_trustedNow() == null) return;
      _totalDrivingHours += 1 / 60; // زيادة دقيقة واحدة
      _cycleHours += 1 / 60;
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
  void reset() {
    _stopDrivingTimer();
    _currentStatus = DutyStatus.offDuty;
    _shiftStartTime = _trustedNow() ?? DateTime.utc(1970);
    _totalDrivingHours = 0.0;
    _cycleHours = 0.0;
    _transitions.clear();
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

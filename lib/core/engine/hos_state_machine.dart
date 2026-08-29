import 'package:golden_feather_eld/core/engine/hos_models.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';
import 'hos_rules_engine.dart';
import 'hos_calculator.dart';

/// آلة حالات ساعات الخدمة
class HosStateMachine {
  DutyStatus _currentStatus = DutyStatus.offDuty;
  DateTime _shiftStartTime = DateTime.now();
  double _totalDrivingHours = 0.0;
  double _cycleHours = 0.0;
  
  final List<StatusTransition> _transitions = [];
  Timer? _drivingTimer;

  // ========== Getters ==========

  DutyStatus get currentStatus => _currentStatus;
  DateTime get shiftStartTime => _shiftStartTime;
  double get totalDrivingHours => _totalDrivingHours;
  double get cycleHours => _cycleHours;

  // ========== التحويلات ==========

  /// الانتقال إلى حالة جديدة
  void transitionTo(DutyStatus newStatus, {String? annotation}) {
    if (_currentStatus == newStatus) return;

    final transition = StatusTransition(
      from: _currentStatus,
      to: newStatus,
      timestamp: DateTime.now(),
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
    if (newStatus == DutyStatus.offDuty || newStatus == DutyStatus.sleeperBerth) {
      // لا نعيد التعيين تلقائياً، يعتمد على مدة الراحة
    }

    AppLogger.info('State transition: ${transition.from.name} → ${transition.to.name}');
  }

  /// بدء مؤقت القيادة
  void _startDrivingTimer() {
    _drivingTimer?.cancel();
    _drivingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
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
    _shiftStartTime = DateTime.now();
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

/// مزود محرك HOS
final hosEngineProvider = Provider<HosRulesEngine>((ref) {
  final calculator = HosCalculator();
  final stateMachine = HosStateMachine();
  return HosRulesEngine(
    calculator: calculator,
    stateMachine: stateMachine,
  );
});



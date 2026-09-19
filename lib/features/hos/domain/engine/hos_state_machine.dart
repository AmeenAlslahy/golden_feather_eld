import 'package:golden_feather_eld/features/hos/domain/engine/hos_models.dart';
import 'dart:async';
import '../../../../core/config/hos_configuration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/logger.dart';
import 'hos_rules_engine.dart';
import 'hos_calculator.dart';
import '../../../../core/time/trusted_time_provider.dart';

/// آلة حالات ساعات الخدمة
class HosStateMachine {
  DutyStatus _currentStatus = DutyStatus.offDuty;
  late DateTime _shiftStartTime;
  double _totalDrivingHours = 0.0;
  double _cycleHours = 0.0;

  final List<StatusTransition> _transitions = [];
  Timer? _drivingTimer;
  final TrustedTimeProvider _timeProvider;

  HosStateMachine(this._timeProvider) {
    _shiftStartTime = _getCurrentTime();
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
  double get totalDrivingHours => _totalDrivingHours;
  double get cycleHours => _cycleHours;

  // ========== التحويلات ==========

  /// الانتقال إلى حالة جديدة
  void transitionTo(DutyStatus newStatus, {String? annotation}) {
    if (_currentStatus == newStatus) return;

    final transition = StatusTransition(
      from: _currentStatus,
      to: newStatus,
      timestamp: _getCurrentTime(),
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
    _shiftStartTime = _getCurrentTime();
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

/// مزود الإعدادات (يمكن تغييره لاحقاً ليكون ديناميكياً يقرأ من DB أو SharedPreferences)
final hosConfigurationProvider = Provider<HosConfiguration>((ref) {
  return HosConfiguration.usa70_8();
});

/// مزود محرك HOS
final hosEngineProvider = Provider<HosRulesEngine>((ref) {
  final config = ref.watch(hosConfigurationProvider);
  final timeProvider = ref.watch(trustedTimeProvider);
  final calculator = HosCalculator(config, timeProvider);
  final stateMachine = HosStateMachine(timeProvider);

  ref.onDispose(() {
    stateMachine.dispose();
  });

  return HosRulesEngine(
    calculator: calculator,
    stateMachine: stateMachine,
    timeProvider: timeProvider,
  );
});

import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/time/trusted_time_provider.dart';
import '../../../../core/utils/logger.dart';
import 'hos_calculator.dart';
import 'hos_state_machine.dart';

sealed class HosEngineResult {}

class HosEngineReady extends HosEngineResult {
  final HosStatusUpdate update;
  HosEngineReady(this.update);
}

class HosEngineTimeUnavailable extends HosEngineResult {
  final TrustedTimeState state;
  HosEngineTimeUnavailable(this.state);
}

class HosRulesEngine {
  final HosCalculator _calculator;
  final HosStateMachine _stateMachine;
  final TrustedTimeProvider _timeProvider;

  HosRulesEngine({
    required HosCalculator calculator,
    required HosStateMachine stateMachine,
    required TrustedTimeProvider timeProvider,
  })  : _calculator = calculator,
        _stateMachine = stateMachine,
        _timeProvider = timeProvider;

  /// معالجة حدث جديد من جهاز ELD
  HosEngineResult processEvent(EldEvent event) {
    // 2. حساب الحدود الأربعة
    final limitsResult = _calculator.calculateAllLimits(
      drivingHours: _stateMachine.totalDrivingHours,
      shiftStartTime: _stateMachine.shiftStartTime,
      cycleHours: _stateMachine.cycleHours,
    );

    if (limitsResult is CalculationTimeUnavailable) {
      return HosEngineTimeUnavailable(limitsResult.state);
    }

    final limits = (limitsResult as CalculationSuccess).limits;

    // 3. التحقق من التنبيهات
    final alerts = _generateAlerts(limits);

    // 4. التحقق من الانتهاكات
    final timeResult = _timeProvider.currentTime;
    final violations = _checkViolations(limits, timeResult);

    return HosEngineReady(HosStatusUpdate(
      currentStatus: _stateMachine.currentStatus,
      limits: limits,
      alerts: alerts,
      violations: violations,
      remainingDriveMinutes: limits.remainingDriveMinutes,
      remainingShiftMinutes: limits.remainingShiftMinutes,
      remainingCycleHours: limits.remainingCycleHours,
      breakRequired: limits.breakRequired,
      breakRemainingMinutes: limits.breakRemainingMinutes,
    ));
  }

  /// يقيّم ما إذا كان الانتقال اليدوي مسموحاً بناءً على القواعد
  Either<Failure, void> validateManualTransition({
    required DutyStatus currentStatus,
    required DutyStatus newStatus,
    required double currentSpeedKmh,
    required double speedThresholdKmh,
  }) {
    if (currentStatus == DutyStatus.driving &&
        newStatus != DutyStatus.driving) {
      if (currentSpeedKmh >= speedThresholdKmh) {
        return Left(ServerFailure(
            message:
                'Cannot manually change from DRIVING while vehicle is moving ($currentSpeedKmh km/h)'));
      }
    }
    return const Right(null);
  }

  /// تبديل يدوي للحالة
  void manualTransition(DutyStatus newStatus, {String? annotation}) {
    _stateMachine.transitionTo(newStatus, annotation: annotation);
    AppLogger.info('👤 Manual transition to ${newStatus.name}');
  }

  /// توليد التنبيهات
  List<HosAlert> _generateAlerts(HosLimits limits) {
    final alerts = <HosAlert>[];

    // تنبيهات القيادة
    if (limits.remainingDriveMinutes <= 15 &&
        limits.remainingDriveMinutes > 0) {
      alerts.add(HosAlert(
        type: HosAlertType.drivingExpiring,
        message: '⚠️ 15 دقيقة متبقية للقيادة',
        severity: AlertSeverity.critical,
        remainingMinutes: limits.remainingDriveMinutes,
      ));
    } else if (limits.remainingDriveMinutes <= 30 &&
        limits.remainingDriveMinutes > 15) {
      alerts.add(HosAlert(
        type: HosAlertType.drivingExpiring,
        message: '⚠️ 30 دقيقة متبقية للقيادة',
        severity: AlertSeverity.warning,
        remainingMinutes: limits.remainingDriveMinutes,
      ));
    } else if (limits.remainingDriveMinutes <= 60 &&
        limits.remainingDriveMinutes > 30) {
      alerts.add(HosAlert(
        type: HosAlertType.drivingExpiring,
        message: 'تنبيه: 60 دقيقة متبقية للقيادة',
        severity: AlertSeverity.info,
        remainingMinutes: limits.remainingDriveMinutes,
      ));
    }

    // تنبيه الاستراحة الإلزامية
    if (limits.breakRequired && limits.breakRemainingMinutes > 0) {
      alerts.add(HosAlert(
        type: HosAlertType.breakRequired,
        message: 'استراحة مطلوبة: ${limits.breakRemainingMinutes} دقيقة متبقية',
        severity: AlertSeverity.warning,
        remainingMinutes: limits.breakRemainingMinutes,
      ));
    }

    // تنبيه نافذة العمل
    if (limits.remainingShiftMinutes <= 60 &&
        limits.remainingShiftMinutes > 0) {
      alerts.add(HosAlert(
        type: HosAlertType.shiftExpiring,
        message: 'نافذة العمل على وشك الانتهاء',
        severity: AlertSeverity.warning,
        remainingMinutes: limits.remainingShiftMinutes,
      ));
    }

    return alerts;
  }

  /// التحقق من الانتهاكات
  List<HosViolation> _checkViolations(
      HosLimits limits, TrustedTimeResult timeResult) {
    final violations = <HosViolation>[];

    // We can only stamp violations if time is available.
    // If it's unavailable, the engine handles it upstream via HosEngineTimeUnavailable,
    // but processEvent covers this already.
    if (timeResult is! TrustedTimeAvailable) {
      // A violation without a trusted timestamp is not a legal record.
      return violations;
    }
    final timestamp = timeResult.utc;

    if (limits.remainingDriveMinutes <= 0) {
      violations.add(HosViolation(
        type: HosViolationType.dailyDrivingExceeded,
        level: ViolationLevel.critical,
        message: '❌ تجاوز حد القيادة 11 ساعة',
        timestamp: timestamp,
      ));
    }

    if (limits.remainingShiftMinutes <= 0) {
      violations.add(HosViolation(
        type: HosViolationType.dailyWorkExceeded,
        level: ViolationLevel.critical,
        message: '❌ تجاوز نافذة العمل 14 ساعة',
        timestamp: timestamp,
      ));
    }

    if (limits.remainingCycleHours <= 0) {
      violations.add(HosViolation(
        type: HosViolationType.weeklyDrivingExceeded,
        level: ViolationLevel.critical,
        message: '❌ تجاوز حد الدورة الأسبوعية',
        timestamp: timestamp,
      ));
    }

    return violations;
  }

  /// الحالة الحالية
  HosEngineResult get currentStatus {
    final limitsResult = _calculator.calculateAllLimits(
      drivingHours: _stateMachine.totalDrivingHours,
      shiftStartTime: _stateMachine.shiftStartTime,
      cycleHours: _stateMachine.cycleHours,
    );

    if (limitsResult is CalculationTimeUnavailable) {
      return HosEngineTimeUnavailable(limitsResult.state);
    }

    final limits = (limitsResult as CalculationSuccess).limits;
    final timeResult = _timeProvider.currentTime;
    final violations = _checkViolations(limits, timeResult);

    return HosEngineReady(HosStatusUpdate(
      currentStatus: _stateMachine.currentStatus,
      limits: limits,
      alerts: _generateAlerts(limits),
      violations: violations,
      remainingDriveMinutes: limits.remainingDriveMinutes,
      remainingShiftMinutes: limits.remainingShiftMinutes,
      remainingCycleHours: limits.remainingCycleHours,
      breakRequired: limits.breakRequired,
      breakRemainingMinutes: limits.breakRemainingMinutes,
    ));
  }

  /// إعادة تعيين
  void reset() {
    _stateMachine.reset();
  }

  void dispose() {
    _stateMachine.dispose();
  }
}

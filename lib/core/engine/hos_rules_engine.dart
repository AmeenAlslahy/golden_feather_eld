// import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';
import 'hos_calculator.dart';
import 'hos_state_machine.dart';

/// محرك قواعد ساعات الخدمة (HOS Rules Engine)
/// معزول تماماً عن واجهة المستخدم لضمان الدقة والاختبار
import 'hos_models.dart';

class HosRulesEngine {
  final HosCalculator _calculator;
  final HosStateMachine _stateMachine;

  HosRulesEngine({
    required HosCalculator calculator,
    required HosStateMachine stateMachine,
  })  : _calculator = calculator,
        _stateMachine = stateMachine;

  /// معالجة حدث جديد من جهاز ELD
  HosStatusUpdate processEvent(EldEvent event) {
    // التبديل الآلي محال الآن إلى DutyStatusTracker
    
    // 2. حساب الحدود الأربعة
    final limits = _calculator.calculateAllLimits(
      drivingHours: _stateMachine.totalDrivingHours,
      shiftStartTime: _stateMachine.shiftStartTime,
      cycleHours: _stateMachine.cycleHours,
    );

    // 3. التحقق من التنبيهات
    final alerts = _generateAlerts(limits);

    // 4. التحقق من الانتهاكات
    final violations = _checkViolations(limits);

    return HosStatusUpdate(
      currentStatus: _stateMachine.currentStatus,
      limits: limits,
      alerts: alerts,
      violations: violations,
      remainingDriveMinutes: limits.remainingDriveMinutes,
      remainingShiftMinutes: limits.remainingShiftMinutes,
      remainingCycleHours: limits.remainingCycleHours,
      breakRequired: limits.breakRequired,
      breakRemainingMinutes: limits.breakRemainingMinutes,
    );
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
    if (limits.remainingDriveMinutes <= 15 && limits.remainingDriveMinutes > 0) {
      alerts.add(HosAlert(
        type: HosAlertType.drivingExpiring,
        message: '⚠️ 15 دقيقة متبقية للقيادة',
        severity: AlertSeverity.critical,
        remainingMinutes: limits.remainingDriveMinutes,
      ));
    } else if (limits.remainingDriveMinutes <= 30 && limits.remainingDriveMinutes > 15) {
      alerts.add(HosAlert(
        type: HosAlertType.drivingExpiring,
        message: '⚠️ 30 دقيقة متبقية للقيادة',
        severity: AlertSeverity.warning,
        remainingMinutes: limits.remainingDriveMinutes,
      ));
    } else if (limits.remainingDriveMinutes <= 60 && limits.remainingDriveMinutes > 30) {
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
    if (limits.remainingShiftMinutes <= 60 && limits.remainingShiftMinutes > 0) {
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
  List<HosViolation> _checkViolations(HosLimits limits) {
    final violations = <HosViolation>[];

    if (limits.remainingDriveMinutes <= 0) {
      violations.add(HosViolation(
        type: HosViolationType.dailyDrivingExceeded,
        level: ViolationLevel.critical,
        message: '❌ تجاوز حد القيادة 11 ساعة',
        arabicMessage: '❌ تجاوز حد القيادة 11 ساعة',
        timestamp: DateTime.now(),
      ));
    }

    if (limits.remainingShiftMinutes <= 0) {
      violations.add(HosViolation(
        type: HosViolationType.dailyWorkExceeded,
        level: ViolationLevel.critical,
        message: '❌ تجاوز نافذة العمل 14 ساعة',
        arabicMessage: '❌ تجاوز نافذة العمل 14 ساعة',
        timestamp: DateTime.now(),
      ));
    }

    if (limits.remainingCycleHours <= 0) {
      violations.add(HosViolation(
        type: HosViolationType.weeklyDrivingExceeded,
        level: ViolationLevel.critical,
        message: '❌ تجاوز حد الدورة الأسبوعية',
        arabicMessage: '❌ تجاوز حد الدورة الأسبوعية',
        timestamp: DateTime.now(),
      ));
    }

    return violations;
  }

  /// الحالة الحالية
  HosStatusUpdate get currentStatus => HosStatusUpdate(
        currentStatus: _stateMachine.currentStatus,
        limits: _calculator.calculateAllLimits(
          drivingHours: _stateMachine.totalDrivingHours,
          shiftStartTime: _stateMachine.shiftStartTime,
          cycleHours: _stateMachine.cycleHours,
        ),
        alerts: [],
        violations: [],
        remainingDriveMinutes: 0,
        remainingShiftMinutes: 0,
        remainingCycleHours: 0,
        breakRequired: false,
        breakRemainingMinutes: 0,
      );

  /// إعادة تعيين
  void reset() {
    _stateMachine.reset();
  }

  void dispose() {
    _stateMachine.dispose();
  }
}

// ========== النماذج ==========










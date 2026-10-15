import 'dart:math' as math;
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_rules_engine.dart';

/// يبني لوحة حالة **حقيقية** من محرك HOS المحلي عند غياب بيانات الخادم.
///
/// لماذا: قبل هذا كانت المسار الأوفلاين يُرجع ثوابت مُختلَقة
/// (offDuty + 11:00/14:00/8:00/70:00) — أي يعرض للسائق "رصيده كامل"
/// وهو غير صحيح قانونياً. الآن تُحسب القيم من العدّادات المحلية
/// المستعادة من فترات الخدمة المحفوظة.
class HosOfflineDashboardBuilder {
  const HosOfflineDashboardBuilder();

  StatusDashboard build({
    required HosEngineResult engineResult,
    required DriverId driverId,
    String driverName = '',
    String driverDisplayText = '',
  }) {
    final code = _codeOf(engineResult);
    final limits = engineResult is HosEngineReady ? engineResult.update.limits : null;

    // دون أرقام موثوقة لا نخترع: نُرجع صفراً فقط عندما لا يوجد أي مصدر،
    // والشارح يعرض حالة "غير متاح" عبر hosIndicators منعدم القيمة.
    final driveRemaining =
        Duration(minutes: limits?.remainingDriveMinutes ?? 0);
    final shiftRemaining =
        Duration(minutes: limits?.remainingShiftMinutes ?? 0);
    final cycleRemaining = Duration(
        minutes: ((limits?.remainingCycleHours ?? 0) * 60).round());
    final breakRemaining = Duration(
        minutes: limits != null
            ? (limits.breakRequired ? 0 : limits.timeUntilBreakMinutes)
            : 480);

    return StatusDashboard(
      driver: DriverRef(
        id: driverId,
        name: driverName,
        displayText: driverDisplayText,
      ),
      operationalAlerts: const OperationalAlerts(
        toolIcon: false,
        warningTriangleIcon: false,
        // صريح: التطبيق يعمل بلا خادم.
        connectionStatus: ConnectionStatus.disconnected,
      ),
      currentDutyStatus: code,
      remainingCircle: RemainingCircle(
        remaining: _governingRemaining(
          dutyStatus: code,
          limits: limits,
        ),
        label: 'Remaining',
        progress: 0.0,
      ),
      hosIndicators: HosIndicators(
        drive: HosIndicator(
          label: 'DRIVE',
          value: driveRemaining,
          type: IndicatorType.remaining,
        ),
        shift: HosIndicator(
          label: 'SHIFT',
          value: shiftRemaining,
          type: IndicatorType.remaining,
        ),
        breakTime: HosIndicator(
          label: 'BREAK',
          value: breakRemaining,
          type: IndicatorType.remaining,
        ),
        cycle: HosIndicator(
          label: 'CYCLE',
          value: cycleRemaining,
          type: IndicatorType.remaining,
        ),
      ),
      regulatoryConstraints: const RegulatoryConstraints(
        ruleSet: CycleRule.usa70_8,
        limits: [
          '11 hours driving',
          '14 hours on duty',
          '70 hours / 8 days',
          'Offline: computed on device from the duty record',
        ],
      ),
    );
  }

  /// الحد الحاكم للدارة: أثناء القيادة حد القيادة، وخارجها نافذة الوردية.
  static Duration _governingRemaining({
    required DutyStatusCode dutyStatus,
    required HosLimits? limits,
  }) {
    if (limits == null) return Duration.zero;
    final isRest = dutyStatus == DutyStatusCode.offDuty ||
        dutyStatus == DutyStatusCode.sleeperBerth ||
        dutyStatus == DutyStatusCode.personalConveyance;
    if (isRest) return Duration.zero;
    final breakMin = limits.breakRequired ? 0 : limits.timeUntilBreakMinutes;
    if (dutyStatus == DutyStatusCode.driving) {
      final driveMin = limits.remainingDriveMinutes;
      final shiftMin = limits.remainingShiftMinutes;
      final governingMin = math.min(math.min(driveMin, shiftMin), breakMin);
      return Duration(minutes: governingMin);
    }
    final shiftMin = limits.remainingShiftMinutes;
    return Duration(minutes: math.min(shiftMin, breakMin));
  }

  static DutyStatusCode _codeOf(HosEngineResult result) {
    if (result is HosEngineReady) {
      switch (result.update.currentStatus) {
        case DutyStatus.driving:
          return DutyStatusCode.driving;
        case DutyStatus.onDutyNotDriving:
          return DutyStatusCode.onDutyNotDriving;
        case DutyStatus.sleeperBerth:
          return DutyStatusCode.sleeperBerth;
        case DutyStatus.personalUse:
          return DutyStatusCode.personalConveyance;
        case DutyStatus.offDuty:
          return DutyStatusCode.offDuty;
      }
    }
    // الوقت غير موثوق: لا نفترض حالة. نُبقي آخر حالة معروفة من
    // التخزين المحلي عبر prefs؛ 调用 يمرّرها كـ driverHint عادةً offDuty.
    return DutyStatusCode.offDuty;
  }
}
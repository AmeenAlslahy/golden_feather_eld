import '../../../../core/config/hos_configuration.dart';
import '../../../../features/account/application/models/rules_screen_model.dart';
import '../models/rules_screen_dto.dart';

class RulesScreenMapper {
  static RulesScreenModel toModel(RulesScreenDto dto) {
    return RulesScreenModel(
      ruleSource: dto.ruleSource,
      cycleRule: dto.cycleRule,
      cargoType: dto.cargoType,
      restart: dto.restart,
      restBreak: dto.restBreak,
      sixteenHourException: dto.sixteenHourException,
      options: dto.options,
      editableFields: dto.editableFields.toSet(),
      readOnlyFields: dto.readOnlyFields.toSet(),
      fixedSettings: dto.fixedSettings,
      notice: dto.notice,
      limits: HosConfiguration(
        drivingLimitMinutes: dto.limits.maxDrivingHours * 60,
        shiftLimitMinutes: dto.limits.maxShiftHours * 60,
        cycleLimitHours: dto.limits.cycleHours,
        maxConsecutiveDays: dto.limits.cycleDays,
        // The Rules API does not provide these fields. We provide safe defaults here,
        // but the actual merge logic MUST use PRESERVE_CURRENT on these fields.
        breakDurationMinutes: 30,
        movingSpeedThresholdKmh: 8.0,
        driveBeforeBreakMinutes: 8 * 60,
        weeklyRestartHours: 34,
      ),
    );
  }
}

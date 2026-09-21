class RulesScreenDto {
  final String driverId;
  final String ruleSource;
  final String cycleRule;
  final String cargoType;
  final String restart;
  final String restBreak;
  final bool sixteenHourException;
  final Map<String, List<String>> options;
  final RulesScreenLimitsDto limits;
  final List<String> editableFields;
  final List<String> readOnlyFields;
  final Map<String, dynamic> fixedSettings;
  final String notice;

  const RulesScreenDto({
    required this.driverId,
    required this.ruleSource,
    required this.cycleRule,
    required this.cargoType,
    required this.restart,
    required this.restBreak,
    required this.sixteenHourException,
    required this.options,
    required this.limits,
    required this.editableFields,
    required this.readOnlyFields,
    required this.fixedSettings,
    required this.notice,
  });

  factory RulesScreenDto.fromJson(Map<String, dynamic> json) {
    return RulesScreenDto(
      driverId: json['driver']?.toString() ?? '',
      ruleSource: json['ruleSource'] as String? ?? '',
      cycleRule: json['cycleRule'] as String? ?? '',
      cargoType: json['cargoType'] as String? ?? '',
      restart: json['restart'] as String? ?? '',
      restBreak: json['restBreak'] as String? ?? '',
      sixteenHourException: json['sixteenHourException'] as bool? ?? false,
      options: (json['options'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as List).map((x) => x.toString()).toList()),
          ) ??
          {},
      limits: RulesScreenLimitsDto.fromJson(json['limits'] as Map<String, dynamic>? ?? {}),
      editableFields: (json['editableFields'] as List?)?.map((e) => e.toString()).toList() ?? [],
      readOnlyFields: (json['readOnlyFields'] as List?)?.map((e) => e.toString()).toList() ?? [],
      fixedSettings: json['fixedSettings'] as Map<String, dynamic>? ?? {},
      notice: json['notice'] as String? ?? '',
    );
  }
}

class RulesScreenLimitsDto {
  final int cycleHours;
  final int cycleDays;
  final int maxShiftHours;
  final int maxDrivingHours;
  final int mandatoryRestHours;

  const RulesScreenLimitsDto({
    required this.cycleHours,
    required this.cycleDays,
    required this.maxShiftHours,
    required this.maxDrivingHours,
    required this.mandatoryRestHours,
  });

  factory RulesScreenLimitsDto.fromJson(Map<String, dynamic> json) {
    return RulesScreenLimitsDto(
      cycleHours: (json['cycleHours'] as num?)?.toInt() ?? 0,
      cycleDays: (json['cycleDays'] as num?)?.toInt() ?? 0,
      maxShiftHours: (json['maxShiftHours'] as num?)?.toInt() ?? 0,
      maxDrivingHours: (json['maxDrivingHours'] as num?)?.toInt() ?? 0,
      mandatoryRestHours: (json['mandatoryRestHours'] as num?)?.toInt() ?? 0,
    );
  }
}

class RulesScreenUpdateRequest {
  final String cycleRule;
  final String cargoType;
  final String restart;
  final String restBreak;
  final bool sixteenHourException;

  const RulesScreenUpdateRequest({
    required this.cycleRule,
    required this.cargoType,
    required this.restart,
    required this.restBreak,
    required this.sixteenHourException,
  });

  Map<String, dynamic> toJson() {
    return {
      'cycleRule': cycleRule,
      'cargoType': cargoType,
      'restart': restart,
      'restBreak': restBreak,
      'sixteenHourException': sixteenHourException,
    };
  }
}

class RulesScreenUpdateRequest {
  final String cycleRule;
  final String cargoType;
  final String restart;
  final String restBreak;
  final bool sixteenHourException;

  // New OAS 3.0 canonical fields
  final String? ruleSetId;
  final String? restartType;
  final String? breakPolicy;
  final bool? sixteenHourExceptionEnabled;
  final bool shortHaulEnabled;
  final bool personalConveyanceAllowed;
  final bool yardMovesAllowed;
  final bool oilGasExceptionAllowed;
  final bool weatherExceptionAllowed;
  final String reason;

  const RulesScreenUpdateRequest({
    required this.cycleRule,
    required this.cargoType,
    required this.restart,
    required this.restBreak,
    required this.sixteenHourException,
    this.ruleSetId,
    this.restartType,
    this.breakPolicy,
    this.sixteenHourExceptionEnabled,
    this.shortHaulEnabled = false,
    this.personalConveyanceAllowed = true,
    this.yardMovesAllowed = true,
    this.oilGasExceptionAllowed = false,
    this.weatherExceptionAllowed = false,
    this.reason = 'تحديث القاعدة الدورية للسائق',
  });

  static String normalizeRuleSetId(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'USA_70_8';
    if (v == 'USA 70/8' || v == 'USA_70HR_8DAY') return 'USA_70_8';
    if (v == 'USA 60/7' || v == 'USA_60HR_7DAY') return 'USA_60_7';
    if (v == 'TEXAS 70/7' || v == 'TEXAS_70HR_7DAY') return 'TEXAS_70_7';
    if (v == 'CALIFORNIA 80/8' || v == 'CALIFORNIA_80HR_8DAY') {
      return 'CALIFORNIA_80_8';
    }
    return v.replaceAll('/', '_').replaceAll(' ', '_');
  }

  static String normalizeRestartType(String value) {
    final v = value.trim();
    if (v.isEmpty) return '34_HOURS';
    if (v == '34h' || v == '34 Hour Restart' || v == 'RESTART_34_HOUR') {
      return '34_HOURS';
    }
    if (v == '24h' || v == '24 Hour Restart' || v == 'RESTART_24_HOUR') {
      return '24_HOURS';
    }
    return v.replaceAll(' ', '_').toUpperCase();
  }

  static String normalizeBreakPolicy(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'REQUIRED_30_MIN';
    if (v == '30m' ||
        v == '30 Minute Rest Break Required' ||
        v == 'REST_BREAK_30_MIN_REQUIRED') {
      return 'REQUIRED_30_MIN';
    }
    if (v == 'Exempt' || v == 'EXEMPT') return 'EXEMPT';
    return v.replaceAll(' ', '_').toUpperCase();
  }

  static String normalizeCargoType(String value) {
    final v = value.trim().toUpperCase();
    if (v == 'PASSENGER') return 'PASSENGER';
    return 'PROPERTY';
  }

  Map<String, dynamic> toJson() {
    final effectiveRuleSetId = ruleSetId ?? normalizeRuleSetId(cycleRule);
    final effectiveRestartType = restartType ?? normalizeRestartType(restart);
    final effectiveBreakPolicy = breakPolicy ?? normalizeBreakPolicy(restBreak);
    final effectiveSixteen =
        sixteenHourExceptionEnabled ?? sixteenHourException;

    return {
      // Legacy fields (for backward compatibility)
      'cycleRule': cycleRule,
      'cargoType': cargoType,
      'restart': restart,
      'restBreak': restBreak,
      'sixteenHourException': sixteenHourException,

      // New OAS 3.0 canonical fields
      'ruleSetId': effectiveRuleSetId,
      'restartType': effectiveRestartType,
      'breakPolicy': effectiveBreakPolicy,
      'sixteenHourExceptionEnabled': effectiveSixteen,
      'shortHaulEnabled': shortHaulEnabled,
      'personalConveyanceAllowed': personalConveyanceAllowed,
      'yardMovesAllowed': yardMovesAllowed,
      'oilGasExceptionAllowed': oilGasExceptionAllowed,
      'weatherExceptionAllowed': weatherExceptionAllowed,
      'reason': reason,
    };
  }
}

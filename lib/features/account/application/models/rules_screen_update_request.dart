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

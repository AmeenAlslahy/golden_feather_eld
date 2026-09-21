class ReadinessDto {
  final int dailyLogId;
  final int driverId;
  final String driverName;
  final String logDate;
  final String readinessStatus;
  final List<String> missingRequirements;
  final String legalStatement;
  final List<String> availableActions;

  const ReadinessDto({
    required this.dailyLogId,
    required this.driverId,
    required this.driverName,
    required this.logDate,
    required this.readinessStatus,
    required this.missingRequirements,
    required this.legalStatement,
    required this.availableActions,
  });

  factory ReadinessDto.fromJson(Map<String, dynamic> json) {
    return ReadinessDto(
      dailyLogId: (json['dailyLogId'] as num?)?.toInt() ?? 0,
      driverId: (json['driverId'] as num?)?.toInt() ?? 0,
      driverName: json['driverName']?.toString() ?? '',
      logDate: json['logDate']?.toString() ?? '',
      readinessStatus: json['readinessStatus']?.toString() ?? 'NOT_READY',
      missingRequirements: (json['missingRequirements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      legalStatement: json['legalStatement']?.toString() ?? '',
      availableActions: (json['availableActions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

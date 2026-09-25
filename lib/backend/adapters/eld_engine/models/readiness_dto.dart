class CarrierProposedEdit {
  final String id;
  final String? carrierName;
  final String? carrierReason;
  final String? proposedStatus;
  final String? previousValuesSummary;
  final String? newValuesSummary;

  const CarrierProposedEdit({
    required this.id,
    this.carrierName,
    this.carrierReason,
    this.proposedStatus,
    this.previousValuesSummary,
    this.newValuesSummary,
  });

  factory CarrierProposedEdit.fromJson(Map<String, dynamic> json) {
    return CarrierProposedEdit(
      id: '${json['id'] ?? ''}'.trim(),
      carrierName: json['carrierName']?.toString(),
      carrierReason: json['carrierReason']?.toString(),
      proposedStatus: json['proposedStatus']?.toString(),
      previousValuesSummary: json['previousValuesSummary']?.toString(),
      newValuesSummary: json['newValuesSummary']?.toString(),
    );
  }
}

class ReadinessDto {
  final int dailyLogId;
  final int driverId;
  final String driverName;
  final String logDate;
  final String readinessStatus;
  final List<String> missingRequirements;
  final String legalStatement;
  final List<String> availableActions;
  final bool carrierProposedEditsPending;
  final List<CarrierProposedEdit> pendingCarrierEdits;

  const ReadinessDto({
    required this.dailyLogId,
    required this.driverId,
    required this.driverName,
    required this.logDate,
    required this.readinessStatus,
    required this.missingRequirements,
    required this.legalStatement,
    required this.availableActions,
    this.carrierProposedEditsPending = false,
    this.pendingCarrierEdits = const [],
  });

  factory ReadinessDto.fromJson(Map<String, dynamic> json) {
    final rawEdits = json['pendingCarrierEdits'];
    final edits = rawEdits is List
        ? rawEdits
            .whereType<Map>()
            .map((item) => CarrierProposedEdit.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .where((edit) => edit.id.isNotEmpty)
            .toList()
        : const <CarrierProposedEdit>[];
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
      carrierProposedEditsPending:
          json['carrierProposedEditsPending'] == true || edits.isNotEmpty,
      pendingCarrierEdits: edits,
    );
  }
}

import 'package:equatable/equatable.dart';

class CarrierProposedEditEntity extends Equatable {
  final String id;
  final String? carrierName;
  final String? carrierReason;
  final String? proposedStatus;
  final String? previousValuesSummary;
  final String? newValuesSummary;

  const CarrierProposedEditEntity({
    required this.id,
    this.carrierName,
    this.carrierReason,
    this.proposedStatus,
    this.previousValuesSummary,
    this.newValuesSummary,
  });

  @override
  List<Object?> get props => [
        id,
        carrierName,
        carrierReason,
        proposedStatus,
        previousValuesSummary,
        newValuesSummary,
      ];
}

class LogReadiness extends Equatable {
  final int dailyLogId;
  final int driverId;
  final String driverName;
  final String logDate;
  final String readinessStatus;
  final List<String> missingRequirements;
  final String legalStatement;
  final List<String> availableActions;
  final bool carrierProposedEditsPending;
  final List<CarrierProposedEditEntity> pendingCarrierEdits;

  const LogReadiness({
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

  @override
  List<Object?> get props => [
        dailyLogId,
        driverId,
        driverName,
        logDate,
        readinessStatus,
        missingRequirements,
        legalStatement,
        availableActions,
        carrierProposedEditsPending,
        pendingCarrierEdits,
      ];
}

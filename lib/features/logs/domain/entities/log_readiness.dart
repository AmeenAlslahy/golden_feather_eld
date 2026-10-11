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

  /// Joined summary of the proposed edit: carrier · proposedStatus · newValuesSummary · reason
  String get displaySummary {
    return [
      if (carrierName != null && carrierName!.trim().isNotEmpty)
        carrierName!.trim(),
      if (proposedStatus != null && proposedStatus!.trim().isNotEmpty)
        proposedStatus!.trim(),
      if (newValuesSummary != null && newValuesSummary!.trim().isNotEmpty)
        newValuesSummary!.trim(),
      if (carrierReason != null && carrierReason!.trim().isNotEmpty)
        carrierReason!.trim(),
    ].join(' · ');
  }

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

  /// Formats raw missing requirement strings by converting ISO timestamps to HH:mm.
  List<String> get formattedMissingRequirements {
    return missingRequirements.map(formatRequirement).toList();
  }

  /// Formats raw timestamp substrings into local 'HH:mm' for human readability.
  static String formatRequirement(String req) {
    return req.replaceAllMapped(
      RegExp(
          r'\d{4}-\d{1,2}-\d{1,2}[T ]\d{1,2}:\d{2}(?::\d{2})?(?:Z|[+-]\d{2}:?\d{2})?'),
      (m) {
        final parsed = DateTime.tryParse(m.group(0)!);
        if (parsed == null) return m.group(0)!;
        final local = parsed.toLocal();
        final hh = local.hour.toString().padLeft(2, '0');
        final mm = local.minute.toString().padLeft(2, '0');
        return '$hh:$mm';
      },
    );
  }

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

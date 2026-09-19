import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/value_objects.dart';

part 'dot_inspection.freezed.dart';

// =============================================================================
// Top-level screen
// =============================================================================

/// Data returned by `GET /eld/dot-inspection`.
@freezed
abstract class DotInspectionScreen with _$DotInspectionScreen {
  const factory DotInspectionScreen({
    required String screenTitle,
    required String guidanceText,
    required String handOverDeviceNotice,
    required String carrierComplianceStatement,
    required String carrierName,
    required String usdotNumber,
    required String eldIdentifier,
    required String eldRegistrationId,
    required DriverId driverId,
    required String driverName,
    required DateTime inspectionDate,
    required int cycleDaysCovered,
    required bool canStartInspection,
    required bool canSendLogs,
    required bool canEmailLogs,
    required bool canViewInformationPacket,
    required bool inspectionActive,
    required bool readOnlyMode,
    int? activeInspectionId,
    String? inspectorName,
  }) = _DotInspectionScreen;
}

// =============================================================================
// Cycle (multiple days)
// =============================================================================

/// Data returned by `GET /eld/dot-inspection/cycle`.
@freezed
abstract class DotInspectionCycleDay with _$DotInspectionCycleDay {
  const factory DotInspectionCycleDay({
    required DriverId driverId,
    required String driverName,
    required DateTime logDate,
    required String displayDate,
    required String displayLocation,
    required bool certified,
    required DateTime? certifiedAt,
    required String eldRegistrationId,
    required String eldIdentifier,
    required String eldProvider,
    required String vehicleNumber,
    required String uniqueId,
    required String vin,
    required double startOdometerKm,
    required double endOdometerKm,
    required double totalDistanceKm,
    required double engineHours,
    required String trailers,
    required String shippingDocuments,
    required String carrierName,
    required String usdotNumber,
    required String mainOfficeAddress,
    required String homeTerminalAddress,
    required List<String> activeDataDiagnostics,
    required List<String> activeDeviceMalfunctions,
    required bool exemptDriver,
    String? exemptReason,
    required bool hasUnidentifiedDriving,
    required int unidentifiedDrivingCount,
  }) = _DotInspectionCycleDay;
}

// =============================================================================
// Single day log
// =============================================================================

/// Data returned by `GET /eld/dot-inspection/logs`.
@freezed
abstract class DotInspectionLog with _$DotInspectionLog {
  const factory DotInspectionLog({
    required DriverId driverId,
    required String driverName,
    required DateTime logDate,
    required String displayDate,
    required String displayLocation,
    required bool certified,
    required DateTime? certifiedAt,
    required String eldRegistrationId,
    required String eldIdentifier,
    required String eldProvider,
    required String vehicleNumber,
    required String uniqueId,
    required String vin,
    required double startOdometerKm,
    required double endOdometerKm,
    required double totalDistanceKm,
    required double engineHours,
    required String trailers,
    required String shippingDocuments,
    required String carrierName,
    required String usdotNumber,
    required String mainOfficeAddress,
    required String homeTerminalAddress,
    required List<String> activeDataDiagnostics,
    required List<String> activeDeviceMalfunctions,
    required List<DotInspectionEvent> events,
    required bool readOnly,
  }) = _DotInspectionLog;
}

@freezed
abstract class DotInspectionEvent with _$DotInspectionEvent {
  const factory DotInspectionEvent({
    required int sequenceNumber,
    required String timeEt,
    required String eventCode,
    required String eventType,
    required String description,
    required String location,
    required double odometer,
    required double engineHours,
    required String origin,
    required String notes,
    required bool certificationEvent,
  }) = _DotInspectionEvent;
}

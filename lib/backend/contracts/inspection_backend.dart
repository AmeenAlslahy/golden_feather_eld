import '../../core/result/result.dart';
import '../../domain/inspection/dot_inspection.dart';
import '../../domain/shared/value_objects.dart';
import 'contract_enums.dart';
import 'raw_json.dart';

abstract interface class InspectionBackend {
  /// GET /eld/dot-inspection
  Future<Result<DotInspectionScreen>> getScreen({DriverId? driverId});

  /// GET /eld/dot-inspection/cycle
  Future<Result<List<DotInspectionCycleDay>>> getCycle({
    DriverId? driverId,
    int days = 8,
    DateTime? endDate,
  });

  /// GET /eld/dot-inspection/logs
  Future<Result<DotInspectionLog>> getLogs({
    DriverId? driverId,
    DateTime? date,
  });

  /// POST /eld/dot-inspection/email-logs
  ///
  /// Kept as RawJson until Phase 4 (not legally critical).
  Future<Result<RawJson>> emailLogs({
    required DriverId driverId,
    required String recipientEmail,
    String? routingCode,
    String? comment,
    int? daysCount,
    DateTime? endDate,
  });

  /// GET /eld/dot-inspection/information-packet
  Future<Result<RawJson>> getInformationPacket({DriverId? driverId});

  /// POST /eld/dot-inspection/send-logs
  Future<Result<RawJson>> sendLogs({
    required DriverId driverId,
    required InspectionTransferType transferType,
    required String outputFileComment,
    String? routingCode,
    String? recipientEmail,
    int? daysCount,
    DateTime? endDate,
  });

  /// POST /eld/dot-inspection/start
  Future<Result<RawJson>> startInspection({
    required DriverId driverId,
    String? inspectorName,
    String? inspectorBadge,
    String? inspectorAgency,
    String? location,
    String? notes,
  });

  /// GET /eld/dot-inspection/transfers
  Future<Result<RawJson>> getTransfers({DriverId? driverId});
}

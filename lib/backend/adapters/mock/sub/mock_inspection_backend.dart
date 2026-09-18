import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/contract_enums.dart';
import '../../../contracts/inspection_backend.dart';
import '../../../contracts/raw_json.dart';

/// In-memory mock for [InspectionBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class MockInspectionBackend implements InspectionBackend {
  const MockInspectionBackend();

  @override
  Future<Result<RawJson>> getScreen({DriverId? driverId}) =>
      throw UnimplementedError('MockInspectionBackend.getScreen — Phase 2');

  @override
  Future<Result<RawJson>> getCycle({
    DriverId? driverId,
    int days = 8,
    DateTime? endDate,
  }) =>
      throw UnimplementedError('MockInspectionBackend.getCycle — Phase 2');

  @override
  Future<Result<RawJson>> emailLogs({
    required DriverId driverId,
    required String recipientEmail,
    String? routingCode,
    String? comment,
    int? daysCount,
    DateTime? endDate,
  }) =>
      throw UnimplementedError('MockInspectionBackend.emailLogs — Phase 2');

  @override
  Future<Result<RawJson>> getInformationPacket({DriverId? driverId}) =>
      throw UnimplementedError(
        'MockInspectionBackend.getInformationPacket — Phase 2',
      );

  @override
  Future<Result<RawJson>> getLogs({
    DriverId? driverId,
    DateTime? date,
  }) =>
      throw UnimplementedError('MockInspectionBackend.getLogs — Phase 2');

  @override
  Future<Result<RawJson>> sendLogs({
    required DriverId driverId,
    required InspectionTransferType transferType,
    required String outputFileComment,
    String? routingCode,
    String? recipientEmail,
    int? daysCount,
    DateTime? endDate,
  }) =>
      throw UnimplementedError('MockInspectionBackend.sendLogs — Phase 2');

  @override
  Future<Result<RawJson>> startInspection({
    required DriverId driverId,
    String? inspectorName,
    String? inspectorBadge,
    String? inspectorAgency,
    String? location,
    String? notes,
  }) =>
      throw UnimplementedError(
        'MockInspectionBackend.startInspection — Phase 2',
      );

  @override
  Future<Result<RawJson>> getTransfers({DriverId? driverId}) =>
      throw UnimplementedError('MockInspectionBackend.getTransfers — Phase 2');
}

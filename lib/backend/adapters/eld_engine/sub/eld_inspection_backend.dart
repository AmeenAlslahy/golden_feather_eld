// ignore_for_file: unused_field, unused_import

import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/contract_enums.dart';
import '../../../contracts/inspection_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';

/// ELD Engine implementation of [InspectionBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldInspectionBackend implements InspectionBackend {
  final ApiClient _apiClient;

  const EldInspectionBackend(this._apiClient);

  @override
  Future<Result<RawJson>> getScreen({DriverId? driverId}) =>
      throw UnimplementedError('EldInspectionBackend.getScreen — Phase 2');

  @override
  Future<Result<RawJson>> getCycle({
    DriverId? driverId,
    int days = 8,
    DateTime? endDate,
  }) =>
      throw UnimplementedError('EldInspectionBackend.getCycle — Phase 2');

  @override
  Future<Result<RawJson>> emailLogs({
    required DriverId driverId,
    required String recipientEmail,
    String? routingCode,
    String? comment,
    int? daysCount,
    DateTime? endDate,
  }) =>
      throw UnimplementedError('EldInspectionBackend.emailLogs — Phase 2');

  @override
  Future<Result<RawJson>> getInformationPacket({DriverId? driverId}) =>
      throw UnimplementedError('EldInspectionBackend.getInformationPacket — Phase 2');

  @override
  Future<Result<RawJson>> getLogs({
    DriverId? driverId,
    DateTime? date,
  }) =>
      throw UnimplementedError('EldInspectionBackend.getLogs — Phase 2');

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
      throw UnimplementedError('EldInspectionBackend.sendLogs — Phase 2');

  @override
  Future<Result<RawJson>> startInspection({
    required DriverId driverId,
    String? inspectorName,
    String? inspectorBadge,
    String? inspectorAgency,
    String? location,
    String? notes,
  }) =>
      throw UnimplementedError('EldInspectionBackend.startInspection — Phase 2');

  @override
  Future<Result<RawJson>> getTransfers({DriverId? driverId}) =>
      throw UnimplementedError('EldInspectionBackend.getTransfers — Phase 2');
}

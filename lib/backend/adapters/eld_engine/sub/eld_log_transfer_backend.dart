// ignore_for_file: unused_field, unused_import

import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/log_transfer_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';

/// ELD Engine implementation of [LogTransferBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldLogTransferBackend implements LogTransferBackend {
  final ApiClient _apiClient;

  const EldLogTransferBackend(this._apiClient);

  @override
  Future<Result<RawJson>> submit({
    required DriverId driverId,
    required int days,
    required DateTime startDate,
    required DateTime endDate,
    required String channel,
    required String recipient,
    String? routingCode,
    String? comments,
  }) =>
      throw UnimplementedError('EldLogTransferBackend.submit — Phase 2');

  @override
  Future<Result<RawJson>> getAuditHistory({DriverId? driverId}) =>
      throw UnimplementedError('EldLogTransferBackend.getAuditHistory — Phase 2');

  @override
  Future<Result<RawJson>> preview({
    DriverId? driverId,
    int days = 8,
    DateTime? endDate,
  }) =>
      throw UnimplementedError('EldLogTransferBackend.preview — Phase 2');
}

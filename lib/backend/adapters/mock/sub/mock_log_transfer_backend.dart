import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/log_transfer_backend.dart';
import '../../../contracts/raw_json.dart';

/// In-memory mock for [LogTransferBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class MockLogTransferBackend implements LogTransferBackend {
  const MockLogTransferBackend();

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
      throw UnimplementedError('MockLogTransferBackend.submit — Phase 2');

  @override
  Future<Result<RawJson>> getAuditHistory({DriverId? driverId}) =>
      throw UnimplementedError(
        'MockLogTransferBackend.getAuditHistory — Phase 2',
      );

  @override
  Future<Result<RawJson>> preview({
    DriverId? driverId,
    int days = 8,
    DateTime? endDate,
  }) =>
      throw UnimplementedError('MockLogTransferBackend.preview — Phase 2');
}

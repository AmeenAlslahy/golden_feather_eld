import '../../core/domain/shared/value_objects.dart';
import '../../core/result/result.dart';
import 'raw_json.dart';

abstract interface class LogTransferBackend {
  /// POST /eld/transfer
  Future<Result<RawJson>> submit({
    required DriverId driverId,
    required int days,
    required DateTime startDate,
    required DateTime endDate,
    required String channel,
    required String recipient,
    String? routingCode,
    String? comments,
  });

  /// GET /eld/transfer/audit-history
  Future<Result<RawJson>> getAuditHistory({DriverId? driverId});

  /// GET /eld/transfer/preview
  Future<Result<RawJson>> preview({
    DriverId? driverId,
    int days = 8,
    DateTime? endDate,
  });
}

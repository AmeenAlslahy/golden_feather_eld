import '../../core/domain/shared/value_objects.dart';
import '../../core/result/result.dart';
import 'contract_enums.dart';
import 'raw_json.dart';

abstract interface class UnidentifiedEventsBackend {
  /// GET /eld/unidentified-events
  Future<Result<RawJson>> list({
    UnidentifiedTab tab = UnidentifiedTab.unclaimed,
    String? uniqueId,
    DriverId? driverId,
  });

  /// POST /eld/unidentified-events/{id}/claim
  Future<Result<void>> claim({
    required DutyStatusId id,
    required DriverId driverId,
    required String annotation,
  });

  /// POST /eld/unidentified-events/{id}/reject
  Future<Result<void>> reject({
    required DutyStatusId id,
    required DriverId driverId,
    required String rejectionReason,
  });
}

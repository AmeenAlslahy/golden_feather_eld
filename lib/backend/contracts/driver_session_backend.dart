import '../../core/result/result.dart';
import '../../domain/shared/value_objects.dart';
import 'contract_enums.dart';
import 'raw_json.dart';

abstract interface class DriverSessionBackend {
  /// GET /eld/sessions/{driverId}
  // TODO(P2): replace with DriverSession
  Future<Result<RawJson>> getActiveSession(DriverId driverId);

  /// GET /api/drivers
  Future<Result<List<dynamic>>> getAvailableDrivers();

  /// GET /eld/sessions/{sessionId}/members
  Future<Result<RawJson>> getMembers(int sessionId);

  /// POST /eld/sessions/connect
  // TODO(P2): replace with DriverSession
  Future<Result<RawJson>> connect({
    String? uniqueId,
    bool disconnected = false,
  });

  /// POST /eld/sessions/co-driver
  // TODO(P2): replace with DriverSession
  Future<Result<RawJson>> manageCoDriver({
    required CoDriverAction action,
    DriverId? coDriverId,
    DriverId? newCoDriverId,
    String? uniqueId,
    String? reason,
  });

  /// POST /eld/sessions/primary-driver/switch
  Future<Result<void>> switchPrimaryDriver({
    required DutyStatusAction action,
    required DriverId coDriverId,
    String? reason,
  });
}

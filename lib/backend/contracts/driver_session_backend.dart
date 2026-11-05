import '../../core/result/result.dart';
import '../../domain/shared/value_objects.dart';
import 'contract_enums.dart';
import 'raw_json.dart';

abstract interface class DriverSessionBackend {
  /// GET /eld/sessions/{driverId}
  // TODO(P2): replace with DriverSession
  Future<Result<RawJson>> getActiveSession(DriverId driverId);

  /// GET /eld/sessions/co-drivers
  Future<Result<List<dynamic>>> getAvailableDrivers();

  /// GET /eld/sessions/co-driver
  Future<Result<RawJson>> getCurrentCoDriver();

  /// POST /eld/sessions/connect
  ///
  /// لا توجد Query Parameters؛ كل الحقول تُرسل في جسم الطلب:
  /// `driverId`, `coDriverId`, `deviceId`, `manualMode`, `manualModeEnabled`.
  // TODO(P2): replace with DriverSession
  Future<Result<RawJson>> connect({
    String? uniqueId,
    bool disconnected = false,
    DriverId? driverId,
    DriverId? coDriverId,
  });

  /// POST /eld/sessions/disconnect
  Future<Result<RawJson>> disconnect();

  /// POST /eld/sessions/primary-driver/switch
  Future<Result<void>> switchPrimaryDriver({
    required DutyStatusAction action,
    required DriverId coDriverId,
    String? reason,
  });
}

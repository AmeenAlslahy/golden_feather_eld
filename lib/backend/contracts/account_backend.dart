import '../../core/domain/account/driver_account.dart';
import '../../core/domain/shared/value_objects.dart';
import '../../core/result/result.dart';
import 'raw_json.dart';

abstract interface class AccountBackend {
  /// GET /eld/profile/{driverId}
  // TODO(P2): replace with UserProfile
  Future<Result<RawJson>> getProfile(DriverId driverId);

  /// PUT /eld/profile/{driverId}
  // TODO(P2): replace with UserProfile
  Future<Result<RawJson>> updateProfile({
    required DriverId driverId,
    required RawJson update,
  });

  /// GET /eld/account
  Future<Result<DriverAccount>> getMyAccount({DriverId? driverId});

  /// PUT /eld/account/preferences
  Future<Result<DriverAccount>> updatePreferences({
    required String language,
    required String odometerUnit,
  });
}

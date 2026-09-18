import '../../core/result/result.dart';
import '../../domain/shared/value_objects.dart';
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
  // TODO(P2): replace with UserProfile
  Future<Result<RawJson>> getMyAccount({DriverId? driverId});

  /// PUT /eld/account/preferences
  // TODO(P2): replace with UserProfile
  Future<Result<RawJson>> updatePreferences({
    required String language,
    required String odometerUnit,
  });
}

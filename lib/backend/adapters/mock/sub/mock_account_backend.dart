import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../domain/account/driver_account.dart';
import '../../../contracts/account_backend.dart';
import '../../../contracts/raw_json.dart';
import '../fixtures/account_fixtures.dart';

/// In-memory mock for [AccountBackend].
///
/// **Rule:** Deterministic. Mutations are stored in-memory per instance
/// (not shared across instances).
class MockAccountBackend implements AccountBackend {
  MockAccountBackend();

  final Map<String, RawJson> _profileOverrides = {};

  @override
  Future<Result<RawJson>> getProfile(DriverId driverId) async {
    final override = _profileOverrides[driverId.value.toString()];
    if (override != null) {
      return ok(Map<String, dynamic>.from(override));
    }
    return ok({
      ...accountProfileFixture,
      'id': driverId.value,
    });
  }

  @override
  Future<Result<RawJson>> updateProfile({
    required DriverId driverId,
    required RawJson update,
  }) async {
    final current = await getProfile(driverId);
    return current.mapValue((existing) {
      final merged = {...existing, ...update};
      _profileOverrides[driverId.value.toString()] = merged;
      return merged;
    });
  }

  @override
  Future<Result<DriverAccount>> getMyAccount({DriverId? driverId}) async {
    return ok(DriverAccount.fromJson(accountMyAccountFixture));
  }

  @override
  Future<Result<DriverAccount>> updatePreferences({
    required String language,
    required String odometerUnit,
  }) async {
    return ok(DriverAccount.fromJson({
      ...accountMyAccountFixture,
      'language': language,
      'odometer': odometerUnit,
    }));
  }
}

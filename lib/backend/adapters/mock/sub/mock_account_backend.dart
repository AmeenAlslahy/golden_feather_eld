import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../domain/account/driver_account.dart';
import '../../../contracts/account_backend.dart';
import '../fixtures/account_fixtures.dart';

/// In-memory mock for [AccountBackend].
///
/// **Rule:** Deterministic. Mutations are stored in-memory per instance
/// (not shared across instances).
class MockAccountBackend implements AccountBackend {
  MockAccountBackend();

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

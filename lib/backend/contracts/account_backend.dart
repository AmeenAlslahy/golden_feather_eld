import '../../core/result/result.dart';
import '../../domain/shared/value_objects.dart';
import '../../domain/account/driver_account.dart';

/// بيانات حساب السائق — مصدرها `/eld/account` و`/eld/account/preferences`.
/// مسار `/eld/profile/{id}` أُزيل من العقد بقرار المالك 2026-10-03
/// (كان بلا أي مستدعٍ إنتاجي — قراءة/تحديث البروفايل لم تُربك بشاشة).
abstract interface class AccountBackend {
  /// GET /eld/account
  Future<Result<DriverAccount>> getMyAccount({DriverId? driverId});

  /// PUT /eld/account/preferences
  Future<Result<DriverAccount>> updatePreferences({
    required String language,
    required String odometerUnit,
  });
}

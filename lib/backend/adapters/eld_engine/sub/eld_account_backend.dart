import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/account_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';

/// ELD Engine implementation of [AccountBackend].
class EldAccountBackend implements AccountBackend {
  final ApiClient _apiClient;

  const EldAccountBackend(this._apiClient);

  @override
  Future<Result<RawJson>> getProfile(DriverId driverId) async {
    final res = await _apiClient.get<RawJson>(
      '/eld/profile/${driverId.value}',
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> updateProfile({
    required DriverId driverId,
    required RawJson update,
  }) async {
    final res = await _apiClient.put<RawJson>(
      '/eld/profile/${driverId.value}',
      data: update,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getMyAccount({DriverId? driverId}) async {
    final res = await _apiClient.get<RawJson>(
      '/eld/account',
      queryParameters: driverId != null ? {'driverId': driverId.value} : null,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> updatePreferences({
    required String language,
    required String odometerUnit,
  }) async {
    final res = await _apiClient.put<RawJson>(
      '/eld/account/preferences',
      data: {
        'language': language,
        'odometer': odometerUnit,
      },
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }
}

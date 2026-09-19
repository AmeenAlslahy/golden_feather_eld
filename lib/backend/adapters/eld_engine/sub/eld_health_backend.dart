import '../../../../core/result/result.dart';
import '../../../contracts/health_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';
import '../../../http/eld_endpoints.dart';

/// ELD Engine implementation of [HealthBackend].
class EldHealthBackend implements HealthBackend {
  final ApiClient _apiClient;

  const EldHealthBackend(this._apiClient);

  @override
  Future<Result<void>> checkLiveness() async {
    final result = await _apiClient.get<void>(EldEndpoints.health);

    return result.mapValue((response) {
      if (!response.isSuccess) {
        throw Exception(
          'Health check failed: HTTP ${response.statusCode}',
        );
      }
    });
  }

  @override
  Future<Result<RawJson>> checkDetailed() async {
    final result = await _apiClient.get<RawJson>(
      EldEndpoints.healthDetailed,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return result.mapValue((res) => res.data ?? <String, dynamic>{});
  }
}

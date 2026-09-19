import '../../../../core/result/result.dart';
import '../../../contracts/config_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';
import '../../../http/eld_endpoints.dart';

/// ELD Engine implementation of [ConfigBackend].
class EldConfigBackend implements ConfigBackend {
  final ApiClient _apiClient;

  const EldConfigBackend(this._apiClient);

  @override
  Future<Result<RawJson>> getConfig() async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.config,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getConfigRules() async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.configRegulations,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getSettings() async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.configDbSettings,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getLegacyServerConfig() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/server');
    return response.map((res) {
      if (res.isSuccess && res.data != null) {
        return res.data!;
      }
      throw Exception(res.message ?? 'Failed to fetch config');
    });
  }
}

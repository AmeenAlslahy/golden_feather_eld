import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/rules_screen_backend.dart';
import '../../../http/api_client.dart';
import '../../../http/eld_endpoints.dart';

/// ELD Engine implementation of [RulesScreenBackend].
class EldRulesScreenBackend implements RulesScreenBackend {
  final ApiClient _apiClient;

  const EldRulesScreenBackend(this._apiClient);

  @override
  Future<Result<RawJson>> getRulesScreen({DriverId? driverId}) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.rulesScreen,
      queryParameters: driverId != null ? {'driverId': driverId.value} : null,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> saveRulesScreen(RawJson settings) async {
    final res = await _apiClient.put<RawJson>(
      EldEndpoints.rulesScreen,
      data: settings,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }
}

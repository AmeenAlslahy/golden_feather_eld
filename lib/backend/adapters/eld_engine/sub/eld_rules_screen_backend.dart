import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../features/account/application/models/rules_screen_model.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/rules_screen_backend.dart';
import '../../../http/api_client.dart';
import '../../../http/eld_endpoints.dart';
import '../models/rules_screen_dto.dart';
import '../mappers/rules_screen_mapper.dart';

/// ELD Engine implementation of [RulesScreenBackend].
class EldRulesScreenBackend implements RulesScreenBackend {
  final ApiClient _apiClient;

  const EldRulesScreenBackend(this._apiClient);

  @override
  Future<Result<RulesScreenModel>> getRulesScreen({DriverId? driverId}) async {
    final res = await _apiClient.get<RulesScreenDto>(
      EldEndpoints.rulesScreen,
      queryParameters: driverId != null ? {'driverId': driverId.value} : null,
      parser: (data) => RulesScreenDto.fromJson(data as Map<String, dynamic>),
    );
    return res.mapValue((r) => RulesScreenMapper.toModel(r.data!));
  }

  @override
  Future<Result<RulesScreenModel>> saveRulesScreen({
    required DriverId driverId,
    required RawJson update,
  }) async {
    final res = await _apiClient.put<RulesScreenDto>(
      EldEndpoints.rulesScreen,
      data: update,
      parser: (data) => RulesScreenDto.fromJson(data as Map<String, dynamic>),
    );
    return res.mapValue((r) => RulesScreenMapper.toModel(r.data!));
  }
}


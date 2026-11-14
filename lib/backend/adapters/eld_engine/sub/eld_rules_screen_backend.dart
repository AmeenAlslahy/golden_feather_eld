import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../features/account/application/models/rules_screen_model.dart'; // ignore_architecture
import '../../../contracts/raw_json.dart';
import '../../../contracts/rules_screen_backend.dart';
import '../../../../core/network/api_client.dart';
import '../../../http/eld_endpoints.dart';
import '../models/rules_screen_dto.dart';
import '../mappers/rules_screen_mapper.dart';

/// ELD Engine implementation of [RulesScreenBackend].
class EldRulesScreenBackend implements RulesScreenBackend {
  final ApiClient _apiClient;

  const EldRulesScreenBackend(this._apiClient);

  @override
  Future<Result<RulesScreenModel>> getRulesScreen({DriverId? driverId}) async {
    // ⚠️ لا نمرر driverId كـ query parameter: المسار هو /eld/driver-rules
    // حيث يستخرج الخادم هوية السائق تلقائياً من توكن المصادقة (Bearer token).
    final res = await _apiClient.get<RulesScreenDto>(
      EldEndpoints.rulesScreen,
      parser: (data) => RulesScreenDto.fromJson(data as Map<String, dynamic>),
    );
    return res.mapValue((r) => RulesScreenMapper.toModel(r.data!));
  }

  @override
  Future<Result<RulesScreenModel>> saveRulesScreen({
    required DriverId driverId,
    required RawJson update,
  }) async {
    var res = await _apiClient.put<dynamic>(
      EldEndpoints.rulesScreen,
      data: update,
    );
    if (res.isLeft() &&
        (res.errorOrNull?.code == '404' ||
            res.errorOrNull?.code.contains('not_found') == true)) {
      res = await _apiClient.put<dynamic>(
        EldEndpoints.driverRules(driverId.value),
        data: update,
      );
    }
    final error = res.errorOrNull;
    if (error != null) return err(error);
    final response = res.valueOrNull!;
    final serverMessage = response.message;
    final body = response.data ?? response.rawBody;
    if (body is Map<String, dynamic> &&
        (body.containsKey('cycleRule') ||
            body.containsKey('ruleSetId') ||
            body.containsKey('rules') ||
            body.containsKey('limits'))) {
      try {
        final model = RulesScreenMapper.toModel(RulesScreenDto.fromJson(body));
        return ok(model.copyWith(serverMessage: serverMessage));
      } catch (_) {
        // Empty/partial PUT body is not a blank rules screen.
      }
    }
    final refreshed = await getRulesScreen();
    return refreshed.mapValue((m) => m.copyWith(serverMessage: serverMessage));
  }
}

import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/result/result.dart';
import '../../../contracts/compliance_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';
import '../../../http/eld_endpoints.dart';

/// ELD Engine implementation of [ComplianceBackend].
class EldComplianceBackend implements ComplianceBackend {
  final ApiClient _apiClient;

  const EldComplianceBackend(this._apiClient);

  @override
  Future<Result<RawJson>> evaluate(DriverId driverId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.evaluateCompliance(driverId.value),
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getRemaining(DriverId driverId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.complianceRemaining(driverId.value),
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }
}

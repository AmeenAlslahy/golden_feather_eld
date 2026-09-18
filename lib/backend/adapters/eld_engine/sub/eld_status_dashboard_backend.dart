import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/status_dashboard_backend.dart';
import '../../../http/api_client.dart';

/// ELD Engine implementation of [StatusDashboardBackend].
class EldStatusDashboardBackend implements StatusDashboardBackend {
  final ApiClient _apiClient;

  const EldStatusDashboardBackend(this._apiClient);

  @override
  Future<Result<RawJson>> getDashboard({DriverId? driverId}) async {
    final res = await _apiClient.get<RawJson>(
      '/eld/status',
      queryParameters: driverId != null ? {'driverId': driverId.value} : null,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> updateDutyStatus({
    required String dutyStatus,
    String? notes,
  }) async {
    final res = await _apiClient.post<RawJson>(
      '/eld/status/duty-status',
      data: {
        'dutyStatus': dutyStatus,
        if (notes != null) 'notes': notes,
      },
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getWeeklyRecap({DriverId? driverId}) async {
    final res = await _apiClient.get<RawJson>(
      '/eld/status/recap',
      queryParameters: driverId != null ? {'driverId': driverId.value} : null,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }
}

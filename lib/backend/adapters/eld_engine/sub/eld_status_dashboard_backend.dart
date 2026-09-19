import '../../../../core/result/result.dart';
import '../../../../domain/duty_status/duty_status_code.dart';
import '../../../../domain/duty_status/status_dashboard.dart';
import '../../../../domain/duty_status/weekly_recap.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/status_dashboard_backend.dart';
import '../../../http/api_client.dart';
import '../../../http/eld_endpoints.dart';
import '../mappers/status_dashboard_mapper.dart';

/// ELD Engine implementation of [StatusDashboardBackend].
class EldStatusDashboardBackend implements StatusDashboardBackend {
  final ApiClient _apiClient;

  const EldStatusDashboardBackend(this._apiClient);

  @override
  Future<Result<StatusDashboard>> getDashboard({DriverId? driverId}) {
    return _apiClient
        .get<Map<String, dynamic>>(
          EldEndpoints.status,
          queryParameters:
              driverId != null ? {'driverId': driverId.value} : null,
          parser: (data) => data is Map<String, dynamic> ? data : {},
        )
        .then((result) => result.mapValue(
          (response) => StatusDashboardMapper.fromDashboardJson(
            response.data ?? const {},
          ),
        ));
  }

  @override
  Future<Result<StatusDashboard>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
  }) {
    return _apiClient
        .post<Map<String, dynamic>>(
          EldEndpoints.dutyStatusPost,
          data: {
            'dutyStatus': status.wire,
            if (notes != null) 'notes': notes,
          },
          parser: (data) => data is Map<String, dynamic> ? data : {},
        )
        .then((result) => result.mapValue(
          (response) => StatusDashboardMapper.fromDashboardJson(
            response.data ?? const {},
          ),
        ));
  }

  @override
  Future<Result<WeeklyRecap>> getWeeklyRecap({DriverId? driverId}) {
    return _apiClient
        .get<Map<String, dynamic>>(
          EldEndpoints.statusRecap,
          queryParameters:
              driverId != null ? {'driverId': driverId.value} : null,
          parser: (data) => data is Map<String, dynamic> ? data : {},
        )
        .then((result) => result.mapValue(
          (response) => StatusDashboardMapper.fromRecapJson(
            response.data ?? const {},
          ),
        ));
  }
}

import 'dart:convert' as dart_convert;
import 'package:dio/dio.dart';
import '../../../../core/result/result.dart';
import '../../../../core/utils/logger.dart';
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
          EldEndpoints.updateDutyStatus,
          data: {
            'dutyStatus': status.wire,
            if (notes != null) 'notes': notes,
          },
          responseType: ResponseType.plain,
          parser: (data) {
            if (data is String) {
              if (data.trim().isEmpty) return <String, dynamic>{};
              try {
                final parsed = dart_convert.jsonDecode(data);
                if (parsed is Map<String, dynamic>) {
                  // If the backend wraps the data in a "data" object, unwrap it if needed,
                  // but StatusDashboardMapper handles that or expects the raw data.
                  // Wait, ApiResponse.fromBody already unwraps `data` or `body`?
                  // No, ApiResponse just takes the parsed body.
                  return parsed;
                }
                AppLogger.warning(
                  'updateDutyStatus: 200 body is JSON but not an object '
                  '(${parsed.runtimeType})',
                );
              } catch (e) {
                // جسم 200 غير فارغ وغير JSON = انحراف عقد يجب أن يبقى مرئياً.
                AppLogger.warning(
                  'updateDutyStatus: 200 body (${data.length} chars) is not '
                  'JSON — mapper will treat it as empty',
                  e,
                );
              }
            }
            if (data is Map<String, dynamic>) return data;
            return <String, dynamic>{};
          },
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

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exception.dart';
import '../models/log_model.dart';

abstract class LogRemoteDataSource {
  Future<List<LogEventModel>> getDutyStatusLogs(int driverId, DateTime date);
}

class LogRemoteDataSourceImpl implements LogRemoteDataSource {
  final ApiClient _apiClient;
  final ApiEndpoints _endpoints;

  LogRemoteDataSourceImpl(this._apiClient, this._endpoints);

  @override
  Future<List<LogEventModel>> getDutyStatusLogs(
      int driverId, DateTime date) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        _endpoints.driverDutyStatus(driverId),
        queryParameters: {
          'date': date.toIso8601String().split('T').first,
        },
      );

      if (!response.status || response.data == null) {
        throw const ServerException(
          message: 'Failed to fetch logs',
        );
      }

      final data = response.data!.containsKey('data')
          ? response.data!['data'] as List<dynamic>
          : (response.data!['events'] as List<dynamic>? ?? []);

      return data
          .map((json) => LogEventModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ServerException && e.statusCode == 404) {
        // No logs for this day on server, return empty
        return [];
      }
      throw ServerException(
        message: 'Network error: $e',
      );
    } catch (e) {
      // If endpoint is unsupported or throws format error
      return []; // Silently fallback to local storage
    }
  }
}

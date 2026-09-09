import '../../../../core/error/exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

abstract class SyncRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchDutyLogs(int driverId);
}

class SyncRemoteDataSourceImpl implements SyncRemoteDataSource {
  final ApiClient apiClient;
  final ApiEndpoints endpoints;

  SyncRemoteDataSourceImpl({
    required this.apiClient,
    required this.endpoints,
  });

  @override
  Future<List<Map<String, dynamic>>> fetchDutyLogs(int driverId) async {
    try {
      final response = await apiClient.get<dynamic>(
        endpoints.dutyStatusLogs,
        queryParameters: {'driverId': driverId},
      );

      if (response.status && response.data != null) {
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('logs')) {
          return List<Map<String, dynamic>>.from(data['logs']);
        }
        return [];
      } else {
        throw ServerException(
          message: response.message ?? 'Failed to fetch duty logs',
        );
      }
    } catch (e) {
      if (e is ServerException || e is OfflineException) rethrow;
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }
}

import '../../../../core/error/exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

abstract class CoDriverRemoteDataSource {
  Future<List<Map<String, dynamic>>> getAvailableDrivers();
}

class CoDriverRemoteDataSourceImpl implements CoDriverRemoteDataSource {
  final ApiClient apiClient;
  final ApiEndpoints endpoints;

  CoDriverRemoteDataSourceImpl({
    required this.apiClient,
    required this.endpoints,
  });

  @override
  Future<List<Map<String, dynamic>>> getAvailableDrivers() async {
    try {
      final response = await apiClient.get<List<dynamic>>(endpoints.drivers);
      
      if (response.status && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data!);
      } else {
        throw ServerException(
          message: response.message ?? 'Failed to fetch drivers',
        );
      }
    } catch (e) {
      if (e is ServerException || e is OfflineException) {
        rethrow;
      }
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }
}

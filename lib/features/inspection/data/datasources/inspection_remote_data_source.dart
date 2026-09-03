import '../../../../core/error/exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/inspection_data.dart';

abstract class InspectionRemoteDataSource {
  Future<List<Map<String, dynamic>>> getInspectionReport(int driverId);
  Future<void> exportInspectionData(int driverId, TransferMethod method, String? email, bool isErods);
}

class InspectionRemoteDataSourceImpl implements InspectionRemoteDataSource {
  final ApiClient apiClient;
  final ApiEndpoints endpoints;

  InspectionRemoteDataSourceImpl({
    required this.apiClient,
    required this.endpoints,
  });

  @override
  Future<List<Map<String, dynamic>>> getInspectionReport(int driverId) async {
    try {
      final response = await apiClient.get<dynamic>(
        endpoints.driverInspectionReport(driverId),
      );
      
      if (response.status && response.data != null) {
        // Assume backend returns { "days": [...] } or just [...]
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('days')) {
          return List<Map<String, dynamic>>.from(data['days']);
        }
        return [];
      } else {
        throw ServerException(
          message: response.message ?? 'Failed to fetch inspection report',
        );
      }
    } catch (e) {
      if (e is ServerException || e is OfflineException) rethrow;
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> exportInspectionData(int driverId, TransferMethod method, String? email, bool isErods) async {
    try {
      final response = await apiClient.post<dynamic>(
        endpoints.inspectionExport(driverId),
        data: {
          'method': method.name,
          'email': email,
          'isErods': isErods,
        },
      );

      if (!response.status) {
        throw ServerException(
          message: response.message ?? 'Failed to export inspection data',
        );
      }
    } catch (e) {
      if (e is ServerException || e is OfflineException) rethrow;
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }
}

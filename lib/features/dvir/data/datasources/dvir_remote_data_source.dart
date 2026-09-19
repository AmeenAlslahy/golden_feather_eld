import '../../../../core/error/exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/dvir_report.dart';

abstract class DvirRemoteDataSource {
  Future<List<Map<String, dynamic>>> getDvirReports(String vehicleId);
  Future<void> submitDvirReport(DvirReport report);
}

class DvirRemoteDataSourceImpl implements DvirRemoteDataSource {
  final ApiClient apiClient;
  final ApiEndpoints endpoints;

  DvirRemoteDataSourceImpl({
    required this.apiClient,
    required this.endpoints,
  });

  @override
  Future<List<Map<String, dynamic>>> getDvirReports(String vehicleId) async {
    try {
      final response = await apiClient.get<List<dynamic>>(
        endpoints.submitInspection(0),
        queryParameters: {'vehicleId': vehicleId},
      );

      if (response.status && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data!);
      } else {
        throw ServerException(
          message: response.message ??
              response.error ??
              'Failed to fetch DVIR reports',
        );
      }
    } catch (e) {
      if (e is ServerException || e is OfflineException) rethrow;
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> submitDvirReport(DvirReport report) async {
    try {
      final data = {
        'id': report.id,
        'type': report.type.name,
        'date': report.date.toIso8601String(),
        'driverName': report.driverName,
        'vehicleId': report.vehicleId,
        'trailerId': report.trailerId,
        'odometer': report.odometer,
        'condition': report.condition.name,
        'signature': report.signature,
        'notes': report.notes,
        'items': report.items
            .map((item) => {
                  'name': item.item.name,
                  'isDefective': item.isDefective,
                  'defectDescription': item.defectDescription,
                })
            .toList(),
      };

      final response = await apiClient.post<dynamic>(
        endpoints.submitInspection(0),
        data: data,
      );

      if (!response.status) {
        throw ServerException(
          message: response.message ??
              response.error ??
              'Failed to submit DVIR report',
        );
      }
    } catch (e) {
      if (e is ServerException || e is OfflineException) rethrow;
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }
}

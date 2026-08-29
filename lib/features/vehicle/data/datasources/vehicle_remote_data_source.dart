import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exception.dart';
import '../../domain/entities/vehicle.dart';

abstract class VehicleRemoteDataSource {
  /// جلب قائمة المركبات المربوطة بحساب المستخدم
  Future<List<Vehicle>> getVehicles();
}

class VehicleRemoteDataSourceImpl implements VehicleRemoteDataSource {
  final ApiClient _apiClient;

  VehicleRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<Vehicle>> getVehicles() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.devices,
      );

      if (!response.status || response.data == null) {
        throw ServerException(
          message: 'Failed to fetch vehicles',
          arabicMessage: 'فشل في جلب قائمة الشاحنات',
        );
      }

      final devicesList = response.data as List<dynamic>;
      
      return devicesList.map((deviceMap) {
        final device = deviceMap as Map<String, dynamic>;
        return Vehicle(
          // Traccar 'uniqueId' is usually used as the identifier for the tracker
          id: device['uniqueId']?.toString() ?? device['id']?.toString() ?? 'unknown',
          name: device['name']?.toString() ?? 'Unknown Vehicle',
          year: device['model']?.toString() ?? 'N/A', // Using model as year if available
          vin: device['uniqueId']?.toString(), // VIN is often stored in uniqueId
          isAssigned: true, // If it's returned by API, it's assigned to this user
        );
      }).toList();
    } on DioException catch (e) {
      throw ServerException(
        message: 'Network error: ${e.message}',
        arabicMessage: 'خطأ في الشبكة',
      );
    }
  }
}

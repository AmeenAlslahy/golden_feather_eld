import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exception.dart';
import '../models/vehicle_model.dart';

abstract class VehicleRemoteDataSource {
  /// جلب قائمة المركبات المربوطة بحساب المستخدم
  Future<List<VehicleModel>> getVehicles();
}

class VehicleRemoteDataSourceImpl implements VehicleRemoteDataSource {
  final ApiClient _apiClient;
  final ApiEndpoints _endpoints;

  VehicleRemoteDataSourceImpl(this._apiClient, this._endpoints);

  @override
  Future<List<VehicleModel>> getVehicles() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        _endpoints.devices,
      );

      if (!response.status || response.data == null) {
        throw const ServerException(
          message: 'Failed to fetch vehicles',
          arabicMessage: 'فشل في جلب قائمة الشاحنات',
        );
      }

      final devicesList = response.data as List<dynamic>;

      return devicesList.map((deviceMap) {
        return VehicleModel.fromJson(deviceMap as Map<String, dynamic>);
      }).toList();
    } on DioException catch (e) {
      throw ServerException(
        message: 'Network error: ${e.message}',
        arabicMessage: 'خطأ في الشبكة',
      );
    }
  }
}

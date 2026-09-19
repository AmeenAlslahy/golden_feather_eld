import '../../../../core/error/exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import 'package:golden_feather_eld/core/data/models/user_model.dart';

abstract class AccountRemoteDataSource {
  Future<UserModel> getUserProfile(int userId);
  Future<UserModel> updateUserProfile(UserModel user);
}

class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  final ApiClient _apiClient;
  final ApiEndpoints _endpoints;

  AccountRemoteDataSourceImpl(this._apiClient, this._endpoints);

  @override
  Future<UserModel> getUserProfile(int userId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${_endpoints.users}/$userId',
      );

      if (!response.status || response.data == null) {
        throw const ServerException(
          message: 'Failed to load user profile',
        );
      }

      // Traccar standard response usually directly returns the object, or wrapped in data
      final data = response.data!.containsKey('data')
          ? response.data!['data'] as Map<String, dynamic>
          : response.data!;

      return UserModel.fromJson(data);
    } catch (e) {
      throw ServerException(
        message: 'Network error: $e',
      );
    }
  }

  @override
  Future<UserModel> updateUserProfile(UserModel user) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '${_endpoints.users}/${user.id}',
        data: user.toJson(),
      );

      if (!response.status || response.data == null) {
        throw const ServerException(
          message: 'Failed to update user profile',
        );
      }

      final data = response.data!.containsKey('data')
          ? response.data!['data'] as Map<String, dynamic>
          : response.data!;

      return UserModel.fromJson(data);
    } catch (e) {
      throw ServerException(
        message: 'Network error: $e',
      );
    }
  }
}

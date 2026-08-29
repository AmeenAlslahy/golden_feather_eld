import 'package:dio/dio.dart';
import '../api_client.dart';
import 'traccar_api_client.dart';

/// تنفيذ واجهة TraccarApiClient باستخدام مكتبة ApiClient الموحدة.
/// يتصل بالمسارات (Endpoints) الحقيقية الموثقة لـ Traccar.
class TraccarApiClientImpl implements TraccarApiClient {
  final ApiClient _apiClient;

  TraccarApiClientImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<Map<String, dynamic>> authenticate(String email, String password) async {
    try {
      final response = await _apiClient.post<dynamic>(
        '/api/session',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      
      if (response.status && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Authentication failed with status: ${response.code}');
      }
    } catch (e) {
      throw Exception('Failed to authenticate: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDevices() async {
    try {
      final response = await _apiClient.get<dynamic>('/api/devices');
      if (response.status && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to get devices: ${response.code}');
      }
    } catch (e) {
      throw Exception('Error getting devices: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPositions(String deviceId) async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/api/positions',
        queryParameters: {'deviceId': deviceId},
      );
      if (response.status && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to get positions: ${response.code}');
      }
    } catch (e) {
      throw Exception('Error getting positions: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEvents(String deviceId, {DateTime? from, DateTime? to}) async {
    try {
      final Map<String, dynamic> queryParams = {'deviceId': deviceId};
      if (from != null) queryParams['from'] = from.toUtc().toIso8601String();
      if (to != null) queryParams['to'] = to.toUtc().toIso8601String();

      final response = await _apiClient.get<dynamic>(
        '/api/events',
        queryParameters: queryParams,
      );
      if (response.status && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to get events: ${response.code}');
      }
    } catch (e) {
      throw Exception('Error getting events: $e');
    }
  }

  @override
  Future<void> updatePosition(Map<String, dynamic> positionData) async {
    try {
      final response = await _apiClient.post<dynamic>('/api/positions', data: positionData);
      if (!response.status && response.code != 202) {
        throw Exception('Failed to update position: ${response.code}');
      }
    } catch (e) {
      throw Exception('Error updating position: $e');
    }
  }
}

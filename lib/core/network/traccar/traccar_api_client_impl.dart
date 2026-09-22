import '../../../backend/http/api_client.dart';
import '../../../features/tracking/data/datasources/traccar_sdk/traccar_api_client.dart';

/// تنفيذ واجهة TraccarApiClient باستخدام مكتبة ApiClient الموحدة.
/// يتصل بالمسارات (Endpoints) الحقيقية الموثقة لـ Traccar.
class TraccarApiClientImpl implements TraccarApiClient {
  final ApiClient _apiClient;

  TraccarApiClientImpl(
      {required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Map<String, dynamic>> authenticate(
      String email, String password) async {
    try {
      final response = await _apiClient.post<dynamic>(
        '/session',
        data: {
          'email': email,
          'password': password,
        },
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      return response.match(
        (error) => throw Exception('Authentication failed: ${error.code}'),
        (res) {
          if (res.isSuccess && res.data != null) {
            return res.data as Map<String, dynamic>;
          } else {
            throw Exception('Authentication failed with status: ${res.statusCode}');
          }
        },
      );
    } catch (e) {
      throw Exception('Failed to authenticate: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDevices() async {
    try {
      final response = await _apiClient.get<dynamic>('/devices');
      return response.match(
        (error) => throw Exception('Error getting devices: ${error.code}'),
        (res) {
          if (res.isSuccess && res.data != null) {
            return List<Map<String, dynamic>>.from(res.data);
          } else {
            throw Exception('Failed to get devices: ${res.statusCode}');
          }
        },
      );
    } catch (e) {
      throw Exception('Error getting devices: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPositions(String deviceId) async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/positions',
        queryParameters: {'deviceId': deviceId},
      );
      return response.match(
        (error) => throw Exception('Error getting positions: ${error.code}'),
        (res) {
          if (res.isSuccess && res.data != null) {
            return List<Map<String, dynamic>>.from(res.data);
          } else {
            throw Exception('Failed to get positions: ${res.statusCode}');
          }
        },
      );
    } catch (e) {
      throw Exception('Error getting positions: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEvents(String deviceId,
      {DateTime? from, DateTime? to}) async {
    try {
      final Map<String, dynamic> queryParams = {'deviceId': deviceId};
      if (from != null) queryParams['from'] = from.toUtc().toIso8601String();
      if (to != null) queryParams['to'] = to.toUtc().toIso8601String();

      final response = await _apiClient.get<dynamic>(
        '/events',
        queryParameters: queryParams,
      );
      return response.match(
        (error) => throw Exception('Error getting events: ${error.code}'),
        (res) {
          if (res.isSuccess && res.data != null) {
            return List<Map<String, dynamic>>.from(res.data);
          } else {
            throw Exception('Failed to get events: ${res.statusCode}');
          }
        },
      );
    } catch (e) {
      throw Exception('Error getting events: $e');
    }
  }

  @override
  Future<void> updatePosition(Map<String, dynamic> positionData) async {
    try {
      final response = await _apiClient.post<dynamic>('/positions',
          data: positionData);
      response.match(
        (error) => throw Exception('Error updating position: ${error.code}'),
        (res) {
          if (!res.isSuccess && res.statusCode != 202) {
            throw Exception('Failed to update position: ${res.statusCode}');
          }
        }
      );
    } catch (e) {
      throw Exception('Error updating position: $e');
    }
  }
}

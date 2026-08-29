import 'package:dio/dio.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mock DioClient for the time being
class DioClient {
  final Dio _dio;

  DioClient() : _dio = Dio();

  void updateBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  Future<Response> post(String path, {dynamic data}) async {
    // Mock response for authentication
    if (path == '/api/auth/login') {
      return Response(
        requestOptions: RequestOptions(path: path),
        data: {
          'user': {
            'id': '1',
            'username': 'admin',
            'email': 'admin@demo.com',
            'full_name': 'Admin User',
            'role': 'admin',
          },
          'token': 'mock_token',
          'refresh_token': 'mock_refresh_token',
          'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        },
        statusCode: 200,
      );
    }
    
    // Mock for refresh
    if (path == '/api/auth/refresh') {
      return Response(
        requestOptions: RequestOptions(path: path),
        data: {
          'user': {
            'id': '1',
            'username': 'admin',
            'email': 'admin@demo.com',
            'full_name': 'Admin User',
            'role': 'admin',
          },
          'token': 'mock_new_token',
          'refresh_token': 'mock_new_refresh_token',
          'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        },
        statusCode: 200,
      );
    }
    
    // Mock for logout
    if (path == '/api/auth/logout') {
      return Response(
        requestOptions: RequestOptions(path: path),
        data: {},
        statusCode: 200,
      );
    }

    throw Exception('Not mocked path $path');
  }

  Future<Response> get(String path) async {
    // Mock for remote config
    if (path.startsWith('/api/config/')) {
      return Response(
        requestOptions: RequestOptions(path: path),
        data: {
          'server_url': 'https://mock-traccar-server.com',
          'interval': 30,
          'distance': 50,
        },
        statusCode: 200,
      );
    }
    
    throw Exception('Not mocked path $path');
  }
}





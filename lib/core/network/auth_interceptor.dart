import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage secureStorage;

  AuthInterceptor(this.secureStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!options.path.contains('/auth/login') && !options.path.contains('/auth/register')) {
      // For token based auth (if used)
      final token = await secureStorage.read(key: 'access_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      
      // For Traccar cookie session
      final sessionJson = await secureStorage.read(key: 'traccar_auth_session');
      if (sessionJson != null) {
        try {
          final Map<String, dynamic> sessionMap = jsonDecode(sessionJson);
          final sessionCredential = sessionMap['sessionCredential'];
          if (sessionCredential != null && sessionCredential.isNotEmpty) {
            final cookie = 'JSESSIONID=$sessionCredential';
            final existingCookie = options.headers['Cookie'];
            if (existingCookie != null) {
              options.headers['Cookie'] = '$existingCookie; $cookie';
            } else {
              options.headers['Cookie'] = cookie;
            }
          }
        } catch (e) {
          // Ignore parse error
        }
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Handle unauthorized / token expiration
      // Fire event to clear session and redirect to login
    }
    super.onError(err, handler);
  }
}

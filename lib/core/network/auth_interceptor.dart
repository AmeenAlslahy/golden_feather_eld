
import 'package:dio/dio.dart';
import '../../features/auth/data/datasources/auth_session_store.dart';
import 'api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  final AuthSessionStore sessionStore;
  final ApiEndpoints endpoints;
  final String backendType;

  AuthInterceptor(this.sessionStore, this.endpoints, this.backendType);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    
    // Ignore login and register endpoints
    if (options.path.contains(endpoints.logIn) || 
        options.path.contains(endpoints.register)) {
      return super.onRequest(options, handler);
    }

    try {
      final session = await sessionStore.getSession();
      
      if (session != null && session.sessionCredential.isNotEmpty) {
        if (backendType == 'eld') {
          // Add Bearer token for ELD server
          options.headers['Authorization'] = 'Bearer ${session.sessionCredential}';
        } else {
          // Add JSESSIONID cookie for Traccar
          final cookie = 'JSESSIONID=${session.sessionCredential}';
          final existingCookie = options.headers['Cookie'];
          options.headers['Cookie'] = existingCookie != null ? '$existingCookie; $cookie' : cookie;
        }
      }
    } catch (_) {
      // Ignore errors when reading session
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // يمكنك إطلاق حدث لتسجيل الخروج
    }
    super.onError(err, handler);
  }
}

import 'package:dio/dio.dart';

import '../../../core/utils/logger.dart';
import '../../../features/auth/data/datasources/auth_local_data_source.dart';

class AuthInterceptor extends Interceptor {
  final AuthLocalDataSource localDataSource;
  final String backendType;
  final void Function()? onUnauthenticated;
  final List<String> allowedDomains;

  AuthInterceptor({
    required this.localDataSource,
    required this.backendType,
    this.onUnauthenticated,
    this.allowedDomains = const [],
  });

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Ignore login and register endpoints
    if (options.path.contains('/session') ||
        options.path.contains('/users') && options.method.toUpperCase() == 'POST') {
      return super.onRequest(options, handler);
    }

    // Security: Only send tokens to allowed domains (or allow all if empty for backwards compatibility)
    if (allowedDomains.isNotEmpty && !allowedDomains.contains(options.uri.host)) {
      AppLogger.warning('AuthInterceptor blocked token for unauthorized domain: ${options.uri.host}');
      return super.onRequest(options, handler);
    }

    try {
      final session = await localDataSource.getSession();

      if (session != null && session.sessionCredential.isNotEmpty) {
        // Traccar uses JSESSIONID cookie for all authenticated requests
        final cookie = 'JSESSIONID=${session.sessionCredential}';
        final existingCookie = options.headers['Cookie'];
        options.headers['Cookie'] =
            existingCookie != null ? '$existingCookie; $cookie' : cookie;
      }
    } catch (e) {
      AppLogger.error('AuthInterceptor failed to read session: $e');
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      if (onUnauthenticated != null) {
        onUnauthenticated!();
      }
    }
    super.onError(err, handler);
  }
}

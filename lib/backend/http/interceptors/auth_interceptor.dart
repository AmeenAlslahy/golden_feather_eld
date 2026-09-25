import 'package:dio/dio.dart';

import '../../../core/utils/logger.dart';
import '../../../features/auth/data/datasources/auth_local_data_source.dart';
import '../eld_endpoints.dart';

/// Attaches the session cookie issued by `POST /api/session`.
///
/// The live host rejects JSON login with HTTP 415 and creates the session in
/// Traccar `SessionResource`, which sets `JSESSIONID`. A stored backend label
/// is not an authentication scheme, so this does not send `Authorization:
/// Bearer` or `?token=`.
class AuthInterceptor extends Interceptor {
  final AuthLocalDataSource localDataSource;
  final String backendType;
  final void Function()? onUnauthenticated;

  AuthInterceptor({
    required this.localDataSource,
    required this.backendType,
    this.onUnauthenticated,
  });

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // لا نستثني إلا نقطة إنشاء الجلسة نفسها؛ contains('/session') كانت
    // تخطّي أي مسار يحتوي الكلمة (مثل /eld/sessions/123/members).
    if (options.path == EldEndpoints.session ||
        options.path.contains('/users') && options.method.toUpperCase() == 'POST') {
      return super.onRequest(options, handler);
    }

    try {
      final session = await localDataSource.getSession();
      if (session != null && session.sessionCredential.isNotEmpty) {
        final cookie = 'JSESSIONID=${session.sessionCredential}';
        final existingCookie = options.headers['Cookie'];
        options.headers['Cookie'] =
            existingCookie != null ? '$existingCookie; $cookie' : cookie;
      }
    } catch (e) {
      AppLogger.error('AuthInterceptor failed to read session for $backendType: $e');
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      onUnauthenticated?.call();
    }
    super.onError(err, handler);
  }
}

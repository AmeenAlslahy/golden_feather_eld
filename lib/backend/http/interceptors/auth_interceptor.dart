import 'package:dio/dio.dart';
import '../../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../../core/utils/logger.dart';
import '../eld_endpoints.dart';

/// Attaches the session cookie issued by `POST /api/session`.
///
/// The live host rejects JSON login with HTTP 415 and creates the session in
/// Traccar `SessionResource`, which sets `JSESSIONID`. A stored backend label
/// is not an authentication scheme, so this does not send `Authorization:
/// Bearer` or `?token=`.
///
/// **أمان الجلسة المخزنة:** رفض 401 لا يُعتبر «انتهاء جلسة» إلا إذا كان
/// الطلب يحمل جلسة فعلاً. الطلبات التي تخرج بلا جلسة (مثل طلب تهيئة
/// الإعدادات عند الإقلاع قبل اكتمال قراءة Keystore) يردّها الخادم 401
/// بشكل طبيعي — اعتبارها انتهاء جلسة كان يمسح التوكن المخزن عند كل
/// إقلاع ويجبر السائق على تسجيل الدخول في كل مرة.
class AuthInterceptor extends Interceptor {
  final AuthLocalDataSource localDataSource;
  final String backendType;
  final void Function()? onUnauthenticated;

  /// علامة على RequestOptions تفيد أن هذا الطلب حمل جلسة فعلاً.
  static const _sessionAttachedKey = 'gf_session_attached';

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
    // (حُذف استثناء POST /users — لم يعد له مستدعٍ وكان يسمح بمرور
    // طلبات إنشاء مستخدمين بلا جلسة، توسيعاً غير مبرر لسطح الهجوم.)
    if (options.path == EldEndpoints.session) {
      return super.onRequest(options, handler);
    }

    try {
      final session = await localDataSource.getSession();
      if (session != null && session.sessionCredential.isNotEmpty) {
        final cookie = 'JSESSIONID=${session.sessionCredential}';
        final existingCookie = options.headers['Cookie'];
        options.headers['Cookie'] =
            existingCookie != null ? '$existingCookie; $cookie' : cookie;
        options.extra[_sessionAttachedKey] = true;
      }
    } catch (e) {
      AppLogger.error('AuthInterceptor failed to read session for $backendType: $e');
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra[_sessionAttachedKey] == true) {
      onUnauthenticated?.call();
    }
    super.onError(err, handler);
  }
}

import 'package:dio/dio.dart';
import '../../../features/auth/data/datasources/auth_local_data_source.dart'; // ignore_architecture
import '../../../core/session/session_epoch.dart';
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

  /// P0 Stage 1: يُستدعى مع epoch الطلب الذي رُفض — المستمع يتجاهل
  /// أي 401 أقدم من الجيل الحالي فلا يطرد جلسة جديدة.
  final void Function(int requestEpoch)? onUnauthenticated;

  /// علامة على RequestOptions تفيد أن هذا الطلب حمل جلسة فعلاً.
  static const _sessionAttachedKey = 'gf_session_attached';

  /// P0 Stage 1: جيل الجلسة الذي أنشأ الطلب — يُقرأ متزامناً لحظة
  /// الإرسال قبل أي await حتى لا يتلوث بجيل أحدث.
  static const epochKey = 'gf_session_epoch';

  /// P0 leak fix: إصدار بيانات الاعتماد لحظة إنشاء الطلب — يُقرأ
  /// متزامناً (getter خالص). عند 401 يُشترط تطابقه مع الحالي، فيُكتشف
  /// الطلب المولود بعد bump وقبل clear (epoch جديد + Cookie قديمة).
  static const credGenKey = 'gf_cred_gen';

  AuthInterceptor({
    required this.localDataSource,
    required this.backendType,
    this.onUnauthenticated,
  });

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // P0 Stage 1: وسم كل طلب (بما فيه إنشاء الجلسة) بجيل منشئه.
    options.extra[epochKey] = SessionEpoch.current;
    // P0 leak fix: وسم إصدار الاعتماد — قراءة متزامنة خالصة.
    options.extra[credGenKey] = localDataSource.credentialGeneration;
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
        final requestHost = options.uri.host;
        final baseHost = Uri.tryParse(options.baseUrl)?.host ?? '';
        
        // Prevent cross-origin cookie leak: only send session cookie to our backend
        if (requestHost == baseHost || requestHost.isEmpty || baseHost.isEmpty) {
          final cookie = 'JSESSIONID=${session.sessionCredential}';
          final existingCookie = options.headers['Cookie'];
          options.headers['Cookie'] =
              existingCookie != null ? '$existingCookie; $cookie' : cookie;
          options.extra[_sessionAttachedKey] = true;
        }
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
      final requestGen = err.requestOptions.extra[credGenKey] as int?;
      if (requestGen != null &&
          requestGen != localDataSource.credentialGeneration) {
        // P0 leak fix: بيانات اعتماد أقدم من المخزن الحالي (طلب وُلد بين
        // bump والمسح، أو جلسة سابقة) — يُتجاهل ولا مساس بالجلسة الجديدة.
        // لا يُطبع أي secret — الأجيال أعداد فقط.
        AppLogger.warning(
            'Ignoring 401 with outdated credential generation');
      } else {
        final requestEpoch = err.requestOptions.extra[epochKey] as int?;
        if (requestEpoch == null ||
            requestEpoch == SessionEpoch.current) {
          onUnauthenticated?.call(requestEpoch ?? SessionEpoch.current);
        } else {
          // P0 Stage 1: 401 قديم من جلسة سابقة — يُتجاهل ولا يطرد الجلسة الجديدة.
          AppLogger.warning(
              'Ignoring stale 401 from epoch $requestEpoch (current ${SessionEpoch.current})');
        }
      }
    }
    super.onError(err, handler);
  }
}

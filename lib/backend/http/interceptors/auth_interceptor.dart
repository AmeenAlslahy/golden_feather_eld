import 'package:dio/dio.dart';
import '../../../core/error/failure.dart';
import '../../../core/session/auth_session.dart';
import '../../../core/session/auth_session_reader.dart';
import '../../../core/session/session_epoch.dart';
import '../../../core/utils/logger.dart';
import '../eld_endpoints.dart';

/// Attaches the session credentials issued by `POST /api/session`.
///
/// The live host rejects JSON login with HTTP 415 and creates the session in
/// Traccar `SessionResource`, which sets `JSESSIONID`. مسارات `/api/eld/**`
/// في عقد OpenAPI محمية بـ `BearerAuth`، لذلك نُرفق رمز Bearer (الصادر من
/// `POST /api/session/token`) متى توفّر، مع إبقاء الكوكي لواجهات Traccar
/// الأصلية.
///
/// **أمان الجلسة المخزنة:** رفض 401 لا يُعتبر «انتهاء جلسة» إلا إذا كان
/// الطلب يحمل جلسة فعلاً. الطلبات التي تخرج بلا جلسة (مثل طلب تهيئة
/// الإعدادات عند الإقلاع قبل اكتمال قراءة Keystore) يردّها الخادم 401
/// بشكل طبيعي — اعتبارها انتهاء جلسة كان يمسح التوكن المخزن عند كل
/// إقلاع ويجبر السائق على تسجيل الدخول في كل مرة.
class AuthInterceptor extends Interceptor {
  final AuthSessionReader localDataSource;
  final String backendType;

  /// P0 Stage 1: يُستدعى مع epoch الطلب الذي رُفض — المستمع يتجاهل
  /// أي 401 أقدم من الجيل الحالي فلا يطرد جلسة جديدة.
  final void Function(int requestEpoch)? onUnauthenticated;

  /// علامة على RequestOptions تفيد أن هذا الطلب حمل جلسة فعلاً.
  static const _sessionAttachedKey = 'gf_session_attached';

  /// علامة على RequestOptions لتخطّي إرفاق الجلسة: يستخدمها الطلب الذي
  /// يبني اعتماده بنفسه (مثل `POST /api/session/token` الذي يمرّر كوكي
  /// الجلسة الجديدة صراحةً) حتى لا تُضاف كوكي/رمز قديمين فوقه.
  static const skipAuthKey = 'gf_skip_auth';

  /// P0 Stage 1: جيل الجلسة الذي أنشأ الطلب — يُقرأ متزامناً لحظة
  /// الإرسال قبل أي await حتى لا يتلوث بجيل أحدث.
  static const epochKey = 'gf_session_epoch';

  /// P0 leak fix: إصدار بيانات الاعتماد لحظة إنشاء الطلب — يُقرأ
  /// متزامناً (getter خالص). عند 401 يُشترط تطابقه مع الحالي، فيُكتشف
  /// الطلب المولود بعد bump وقبل clear (epoch جديد + Cookie قديمة).
  static const credGenKey = 'gf_cred_gen';

  /// P0 2B-1 — المالك المتوقع لعملية الطابور (يضعه الـ dispatcher عبر
  /// ApiClient حصراً لطلبات المزامنة). عند الإرسال الفعلي يُقارن بجلسة
  /// اللحظة: أي اختلاف (تبديل جلسة أثناء الـ awaits السابقة) يرفض
  /// الطلب قبل مغادرة أي بايت — فلا ترث عملية قديمة جلسة جديدة أبداً.
  static const expectedOwnerKey = 'gf_expected_owner';

  /// هوية المالك الحالية **بنفس فضاء الختم** — معرّف سائق ELD كما يُشتق
  /// في `currentDriverIdProvider` (لوحة HOS/ربط الجلسة، بسقوط على مستخدم
  /// Traccar قبل الاكتشاف). كان السياج يقارن الختم بـ `session.user.id`
  /// (معرّف مستخدم Traccar — جدول مختلف عن `eld_drivers`)، فيُرفض كل طلب
  /// ملزم بمالك بمجرد اشتقاق معرّف السائق من الخادم (مراجعة 2026-10-30).
  /// يُحقن من تركيب التطبيق (نمط observeAuth) وتُقرأ لحظة الإرسال لا
  /// لحظة البناء — فلا يمر الختم إلا إذا بقيت الهوية نفسها.
  final Future<int?> Function() resolveCurrentOwnerDriverId;

  AuthInterceptor({
    required this.localDataSource,
    required this.backendType,
    required this.resolveCurrentOwnerDriverId,
    this.onUnauthenticated,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // P0 Stage 1: وسم كل طلب (بما فيه إنشاء الجلسة) بجيل منشئه.
    options.extra[epochKey] = SessionEpoch.current;
    // P0 leak fix: وسم إصدار الاعتماد — قراءة متزامنة خالصة.
    options.extra[credGenKey] = localDataSource.credentialGeneration;
    // لا نستثني إلا نقطة إنشاء الجلسة نفسها؛ contains('/session') كانت
    // تخطّي أي مسار يحتوي الكلمة (مثل /eld/sessions/123/members).
    // (حُذف استثناء POST /users — لم يعد له مستدعٍ وكان يسمح بمرور
    // طلبات إنشاء مستخدمين بلا جلسة، توسيعاً غير مبرر لسطح الهجوم.)
    //
    // `options.uri.path` هي المسار الفعلي بعد إلحاق baseUrl (`/api/session`)،
    // بينما `options.path` قد يكون URL مطلقاً. السلسلة القديمة كانت
    // `'/api\${...}'` ($ مُهرَّب) فلم تطابق أبداً وأُرفقت جلسة قديمة بطلب
    // تسجيل الدخول.
    if (options.extra[skipAuthKey] == true ||
        options.path == EldEndpoints.authSession ||
        options.uri.path == EldEndpoints.authSession ||
        options.uri.path == '/api${EldEndpoints.authSession}') {
      return super.onRequest(options, handler);
    }

    // P0 2B-1 — قراءة جلسة واحدة لكل طلب: كل ما بعدها متزامن بحت
    // داخل نفس الـ microtask (أحادي الخيط: لا تداخل ممكن)، فيكون قرار
    // الإرفاق والتحقق من المالك ذرياً بالنسبة لتغيرات الجلسة.
    AuthSession? session;
    try {
      session = await localDataSource.getSession();
    } catch (e) {
      AppLogger.error(
        'AuthInterceptor failed to read session for $backendType: $e',
      );
    }

    // P0 2B-1 — إنفاذ وقت-الإرسال خارج شرط وجود الجلسة عمداً: طلب مزامنة
    // بلا جلسة حاضرة (logout أثناء الطيران) يُرفض أيضاً — لا إرسال مجهول.
    final expectedOwner = options.extra[expectedOwnerKey];
    if (expectedOwner is int) {
      // المقارنة صاحبة-الفضاء: الختم يأتي من currentDriverIdProvider
      // (معرّف سائق ELD) فيجب أن تُقرأ هوية الإرسال من المصدر نفسه لحظة
      // الإرسال — لا من session.user.id (معرّف مستخدم Traccar، جدول آخر).
      // غياب الهوية (null) أمام ختم موجب = رفض فاشل-مغلق.
      //
      // 🔴 المُحلّل محميّ: أي استثناء من مصدر الهوية يُسجَّل بكامله (سبب
      // الجذر والـ stack) ثم يُعامل كـ null — رفض نظيف فاشل-مغلق بدل
      // DioException(unknown) يفقد التشخيص (حادثة 2026-10-31: PUT events
      // خرج (unknown) بلا أي دليل في السجل).
      int? actualOwner;
      try {
        actualOwner = await resolveCurrentOwnerDriverId();
      } catch (e, st) {
        AppLogger.error(
          'Owner-resolver threw — treating as null (fail-closed refusal)',
          e,
          st,
        );
      }
      if (actualOwner != expectedOwner) {
        AppLogger.warning('Refusing queue dispatch under a different session');
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: OwnerMismatchSignal(
              expectedOwnerDriverId: expectedOwner,
              actualOwnerDriverId: actualOwner,
            ),
          ),
        );
        return;
      }
    }

    if (session != null && session.sessionCredential.isNotEmpty) {
      final requestHost = options.uri.host;
      final baseHost = Uri.tryParse(options.baseUrl)?.host ?? '';

      // Prevent cross-origin credential leak: only send credentials to our backend
      if (requestHost == baseHost || requestHost.isEmpty || baseHost.isEmpty) {
        // عقد ELD (OpenAPI) يعلن `BearerAuth` فقط لمسارات `/api/eld/**`.
        // نرسل الرمز متى توفّر، ونُبقي كوكي JSESSIONID لأن واجهات Traccar
        // الأصلية (المواقع/الأحداث/WebSocket) تعتمد عليه.
        final token = session.bearerToken;
        if (token != null && token.isNotEmpty) {
          options.headers.putIfAbsent(
            'Authorization',
            () => 'Bearer $token',
          );
        }
        final cookie = 'JSESSIONID=${session.sessionCredential}';
        final existingCookie = options.headers['Cookie'];
        options.headers['Cookie'] = existingCookie != null
            ? '$existingCookie; $cookie'
            : cookie;
        options.extra[_sessionAttachedKey] = true;
      }
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
        AppLogger.warning('Ignoring 401 with outdated credential generation');
      } else {
        final requestEpoch = err.requestOptions.extra[epochKey] as int?;
        if (requestEpoch == null || requestEpoch == SessionEpoch.current) {
          onUnauthenticated?.call(requestEpoch ?? SessionEpoch.current);
        } else {
          // P0 Stage 1: 401 قديم من جلسة سابقة — يُتجاهل ولا يطرد الجلسة الجديدة.
          AppLogger.warning(
            'Ignoring stale 401 from epoch $requestEpoch (current ${SessionEpoch.current})',
          );
        }
      }
    }
    super.onError(err, handler);
  }
}

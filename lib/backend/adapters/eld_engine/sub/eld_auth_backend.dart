import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/result/result.dart';
import '../../../../core/error/app_error.dart';
import '../../../contracts/auth_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../../core/network/error_mapper.dart';
import '../../../http/eld_endpoints.dart';
import '../../../http/interceptors/auth_interceptor.dart';

class EldAuthBackend implements AuthBackend {
  final ApiClient _apiClient;

  EldAuthBackend(this._apiClient);

  @override
  Future<Result<RawJson>> login({
    required String identifier,
    required String password,
    required String serverUrl,
    required String backendType,
  }) async {
    try {
      final baseUrl = serverUrl.endsWith('/')
          ? serverUrl.substring(0, serverUrl.length - 1)
          : serverUrl;
      // POST /api/session is Traccar SessionResource. JSON is HTTP 415 on the
      // live host. The stored backend label does not select a second login.
      final response = await _apiClient.dio.post(
        '$baseUrl/api${EldEndpoints.authSession}',
        data: {'email': identifier, 'password': password},
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // 404 = مسار غير موجود، وليس رفضاً للمصادقة؛ إظهاره "بيانات غير صالحة"
      // يُضلّل التشخيص.
      if (response.statusCode == 401 ||
          response.statusCode == 400 ||
          response.statusCode == 403) {
        return err(
          ServerError(
            code: 'unauthorized',
            context: {'statusCode': response.statusCode},
          ),
        );
      } else if (response.statusCode != 200 && response.statusCode != 201) {
        return err(
          ServerError(
            code: 'server_error',
            context: {'statusCode': response.statusCode},
          ),
        );
      }

      dynamic parsedData;
      if (response.data is String) {
        try {
          parsedData = jsonDecode(response.data);
        } catch (_) {
          parsedData = {};
        }
      } else {
        parsedData = response.data;
      }

      parsedData ??= {};

      String? credential;
      final setCookieHeaders = response.headers['set-cookie'] ?? [];
      for (var cookie in setCookieHeaders) {
        final parts = cookie.split(';');
        for (var part in parts) {
          part = part.trim();
          if (part.startsWith('JSESSIONID=')) {
            credential = part.substring('JSESSIONID='.length);
            break;
          }
        }
        if (credential != null) break;
      }

      if (credential == null || credential.isEmpty) {
        return err(
          ServerError(
            code: 'missing_credential',
            context: {'backendType': backendType},
          ),
        );
      }

      // مسارات `/api/eld/**` محمية بـ `BearerAuth` في عقد OpenAPI، بينما
      // تسجيل الدخول يعيد كوكي JSESSIONID. نولّد رمز Bearer بعد إنشاء الجلسة
      // (نفس الكوكي)؛ وفشل التوليد لا يُفشل الدخول — تبقى الجلسة صالحة
      // لواجهات Traccar الأصلية، ويُسجّل السبب فقط.
      final bearerToken = await _fetchBearerToken(
        baseUrl: baseUrl,
        sessionCredential: credential,
      );

      dynamic userData = parsedData;
      if (userData is Map<String, dynamic> &&
          userData.containsKey('data') &&
          userData['status'] == true) {
        userData = userData['data'];
      }
      if (userData is! Map<String, dynamic>) {
        userData = {};
      }

      return ok({
        'credential': credential,
        if (bearerToken != null) 'token': bearerToken,
        'user': userData,
        'serverOrigin': baseUrl,
      });
    } on DioException catch (e) {
      return err(mapDioException(e));
    } catch (e, st) {
      return err(UnknownError(code: 'login_error', cause: e, stackTrace: st));
    }
  }

  /// `POST /api/session/token` — يُصدر رمز Bearer مرتبطاً بالجلسة الحالية.
  ///
  /// يعيد `null` عند أي فشل (مسار غير مدعوم، 401، جسم غير نصي). هذا مقصود:
  /// الرمز إضافة، ولا يجوز أن يمنع الدخول الذي نجح بالفعل.
  Future<String?> _fetchBearerToken({
    required String baseUrl,
    required String sessionCredential,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '$baseUrl/api${EldEndpoints.authSession}/token',
        options: Options(
          headers: {'Cookie': 'JSESSIONID=$sessionCredential'},
          // الكوكي هنا جديد ومقصود؛ لا نسمح للـ interceptor بإضافة اعتماد
          // الجلسة المخزنة (قد تكون قديمة/غير ذات صلة) فوقه.
          extra: {AuthInterceptor.skipAuthKey: true},
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        return null;
      }
      final body = response.data;
      if (body is! String) return null;
      final trimmed = body.trim();
      if (trimmed.isEmpty) return null;
      // قد يعيد الخادم الرمز كنص خام أو كسلسلة JSON مغلّفة بعلامات اقتباس.
      if (trimmed.startsWith('"') && trimmed.endsWith('"')) {
        try {
          final decoded = jsonDecode(trimmed);
          return decoded is String && decoded.trim().isNotEmpty
              ? decoded.trim()
              : null;
        } catch (_) {
          return null;
        }
      }
      return trimmed;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<RawJson>> validateSession({
    required String serverOrigin,
    required String sessionCredential,
    required String backendType,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '$serverOrigin/api${EldEndpoints.authSession}',
        options: Options(
          headers: {'Cookie': 'JSESSIONID=$sessionCredential'},
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        return err(
          ServerError(
            code: 'unauthorized',
            context: {
              'statusCode': response.statusCode,
              'backendType': backendType,
            },
          ),
        );
      } else if (response.statusCode != 200) {
        return err(
          ServerError(
            code: 'server_error',
            context: {'statusCode': response.statusCode},
          ),
        );
      }

      dynamic userData = response.data;
      if (userData is Map<String, dynamic> &&
          userData.containsKey('data') &&
          userData['status'] == true) {
        userData = userData['data'];
      }
      if (userData is! Map<String, dynamic>) {
        return err(const ServerError(code: 'invalid_payload'));
      }

      // تجديد/إصدار رمز Bearer عند التحقق: الجلسات المخزنة قبل إضافة الرمز
      // لا تحمله، ومسارات ELD ترفضها. الفشل لا يُفشل التحقق.
      final bearerToken = await _fetchBearerToken(
        baseUrl: serverOrigin,
        sessionCredential: sessionCredential,
      );

      return ok({
        'credential': sessionCredential,
        if (bearerToken != null) 'token': bearerToken,
        'user': userData,
        'serverOrigin': serverOrigin,
      });
    } on DioException catch (e) {
      return err(mapDioException(e));
    } catch (e, st) {
      return err(
        UnknownError(code: 'validate_session_error', cause: e, stackTrace: st),
      );
    }
  }

  @override
  Future<Result<void>> logout({
    required String serverOrigin,
    required String sessionCredential,
    required String backendType,
  }) async {
    try {
      final options = Options(
        headers: {'Cookie': 'JSESSIONID=$sessionCredential'},
        extra: {'backendType': backendType},
        followRedirects: false,
        validateStatus: (status) => true,
      );

      // Defaulting to DELETE for logout
      await _apiClient.dio.delete(
        '$serverOrigin/api${EldEndpoints.authSession}',
        options: options,
      );
      return ok(null);
    } catch (e) {
      // Fail gracefully
      return ok(null);
    }
  }

  @override
  Future<Result<void>> requestPasswordReset({
    required String email,
    required String serverUrl,
  }) async {
    try {
      final baseUrl = serverUrl.endsWith('/')
          ? serverUrl.substring(0, serverUrl.length - 1)
          : serverUrl;
      final response = await _apiClient.dio.post(
        '$baseUrl/api${EldEndpoints.password}',
        data: {'email': email},
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        return ok(null);
      }
      if (response.statusCode == 404) {
        return err(const NotFoundError(code: 'password.resetUnavailable'));
      }
      return err(
        ServerError(
          code: 'password.resetFailed',
          context: {'statusCode': response.statusCode},
        ),
      );
    } on DioException catch (e) {
      return err(mapDioException(e));
    } catch (e, st) {
      return err(
        UnknownError(code: 'password.resetFailed', cause: e, stackTrace: st),
      );
    }
  }
}

import 'package:dio/dio.dart';
import '../../../../core/error/exception.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/auth_session.dart';

abstract class AuthRemoteDataSource {
  /// يقوم بتسجيل الدخول وإنشاء جلسة Traccar
  Future<AuthSession> login({
    required String email,
    required String password,
    required String serverUrl,
  });

  /// إنشاء حساب مستخدم جديد في الخادم
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String serverUrl,
  });

  /// يتحقق من صحة الجلسة الحالية
  Future<AuthSession> validateSession({
    required AuthSession currentSession,
  });

  /// ينهي الجلسة من الخادم
  Future<void> logout({
    required AuthSession currentSession,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
    required String serverUrl,
  }) async {
    // نستخدم عنوان الخادم كاملاً لكي ندعم الباك إند المخصص مستقبلاً
    final baseUrl = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;

    try {
      final response = await _dio.post(
        '$baseUrl${ApiEndpoints.session}',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          // لا تتبع التحويلات لضمان عدم تسريب بيانات المصادقة لـ Origin مختلف
          followRedirects: false, 
          // تجنب رمي أخطاء للتمكن من فحص الرد وتوحيد الأخطاء
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 401) {
        throw const ServerException(message: 'Invalid email or password', arabicMessage: 'البريد الإلكتروني أو كلمة المرور غير صحيحة', statusCode: 401);
      } else if (response.statusCode == 404 || response.statusCode == 405) {
        throw ServerException(message: 'Invalid Traccar API endpoint', arabicMessage: 'نقطة اتصال غير صالحة', statusCode: response.statusCode);
      } else if (response.statusCode != 200) {
        throw ServerException(message: 'Server error: ${response.statusCode}', arabicMessage: 'خطأ في الخادم', statusCode: response.statusCode);
      }

      // تحليل الكوكي لاستخراج JSESSIONID
      final setCookieHeaders = response.headers.map['set-cookie'] ?? [];
      String? jsessionid;
      
      for (var cookie in setCookieHeaders) {
        final parts = cookie.split(';');
        for (var part in parts) {
          part = part.trim();
          if (part.startsWith('JSESSIONID=')) {
            jsessionid = part.substring('JSESSIONID='.length);
            break;
          }
        }
        if (jsessionid != null) break;
      }

      if (jsessionid == null || jsessionid.isEmpty) {
        throw const ServerException(message: 'Missing session cookie from server', arabicMessage: 'ملف تعريف ارتباط الجلسة مفقود');
      }

      final userData = response.data;
      if (userData is! Map<String, dynamic>) {
        throw const ServerException(message: 'Invalid user payload format', arabicMessage: 'صيغة بيانات المستخدم غير صالحة');
      }

      return AuthSession.create(
        serverOrigin: baseUrl,
        sessionCredential: jsessionid,
        userMetadata: userData,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const ServerException(message: 'Invalid email or password', arabicMessage: 'البريد الإلكتروني أو كلمة المرور غير صحيحة', statusCode: 401);
      }
      throw ServerException(message: 'Network error: ${e.message}', arabicMessage: 'خطأ في الشبكة');
    }
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String serverUrl,
  }) async {
    final baseUrl = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;

    try {
      final response = await _dio.post(
        '$baseUrl${ApiEndpoints.register}',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 400 || response.statusCode == 403) {
        throw ServerException(message: 'Registration disabled or invalid data', arabicMessage: 'إنشاء الحساب معطل أو البيانات غير صالحة', statusCode: response.statusCode);
      } else if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(message: 'Server error: ${response.statusCode}', arabicMessage: 'خطأ في الخادم', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 403) {
        throw ServerException(message: 'Registration disabled or invalid data', arabicMessage: 'إنشاء الحساب معطل أو البيانات غير صالحة', statusCode: e.response?.statusCode);
      }
      throw ServerException(message: 'Network error: ${e.message}', arabicMessage: 'خطأ في الشبكة');
    }
  }

  @override
  Future<AuthSession> validateSession({
    required AuthSession currentSession,
  }) async {
    try {
      final response = await _dio.get(
        '${currentSession.serverOrigin}${ApiEndpoints.session}',
        options: Options(
          headers: {
            'Cookie': 'JSESSIONID=${currentSession.sessionCredential}',
          },
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 401 || response.statusCode == 403 || response.statusCode == 404) {
        throw const ServerException(message: 'Session expired or invalid', arabicMessage: 'الجلسة منتهية أو غير صالحة', statusCode: 401);
      } else if (response.statusCode != 200) {
        throw ServerException(message: 'Server error: ${response.statusCode}', arabicMessage: 'خطأ في الخادم', statusCode: response.statusCode);
      }

      final userData = response.data;
      if (userData is! Map<String, dynamic>) {
        throw const ServerException(message: 'Invalid user payload format', arabicMessage: 'صيغة بيانات المستخدم غير صالحة');
      }

      return AuthSession.create(
        serverOrigin: currentSession.serverOrigin,
        sessionCredential: currentSession.sessionCredential,
        userMetadata: userData,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403 || e.response?.statusCode == 404) {
        throw const ServerException(message: 'Session expired or invalid', arabicMessage: 'الجلسة منتهية أو غير صالحة', statusCode: 401);
      }
      // نرمي خطأ شبكة للتمييز بين عدم الاتصال وانتهاء الجلسة
      throw ServerException(message: 'Network error during validation: ${e.message}', arabicMessage: 'خطأ شبكي أثناء التحقق من الجلسة');
    }
  }

  @override
  Future<void> logout({
    required AuthSession currentSession,
  }) async {
    try {
      await _dio.delete(
        '${currentSession.serverOrigin}${ApiEndpoints.session}',
        options: Options(
          headers: {
            'Cookie': 'JSESSIONID=${currentSession.sessionCredential}',
          },
          followRedirects: false,
          validateStatus: (status) => true,
        ),
      );
    } catch (e) {
      // الفشل في إنهاء الجلسة من الخادم (بسبب الشبكة مثلاً) لا يجب أن يمنع تسجيل الخروج محلياً
    }
  }
}

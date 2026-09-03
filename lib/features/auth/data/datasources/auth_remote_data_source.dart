import 'dart:convert' as dart_convert;
import 'package:dio/dio.dart';
import '../../../../core/error/exception.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/auth_session.dart';

abstract class AuthRemoteDataSource {
  /// يقوم بتسجيل الدخول وإنشاء جلسة
  Future<AuthSession> login({
    required String email,
    required String password,
    required String serverUrl,
    required String backendType,
  });

  /// إنشاء حساب مستخدم جديد في الخادم
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String serverUrl,
    required String backendType,
  });

  /// يتحقق من صحة الجلسة الحالية
  Future<AuthSession> validateSession({
    required AuthSession currentSession,
    required String backendType,
  });

  /// ينهي الجلسة من الخادم
  Future<void> logout({
    required AuthSession currentSession,
    required String backendType,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;
  final ApiEndpoints _endpoints;

  AuthRemoteDataSourceImpl(this._dio, this._endpoints);

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
    required String serverUrl,
    required String backendType,
  }) async {
    final baseUrl = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
    final isEld = backendType == 'eld';

    try {
      final response = await _dio.post(
        '$baseUrl${_endpoints.session}',
        data: isEld 
          ? {'email': email, 'password': password}
          : {'email': email, 'password': password}, // Traccar uses formUrlEncoded which Dio handles
        options: Options(
          contentType: isEld ? Headers.jsonContentType : Headers.formUrlEncodedContentType,
          responseType: ResponseType.plain,
          followRedirects: false, 
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 401 || response.statusCode == 400) {
        throw const ServerException(message: 'Invalid email or password', arabicMessage: 'البريد الإلكتروني أو كلمة المرور غير صحيحة', statusCode: 401);
      } else if (response.statusCode == 404 || response.statusCode == 405) {
        throw ServerException(message: 'Invalid API endpoint', arabicMessage: 'نقطة اتصال غير صالحة', statusCode: response.statusCode);
      } else if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(message: 'Server error: ${response.statusCode}', arabicMessage: 'خطأ في الخادم', statusCode: response.statusCode);
      }

      dynamic parsedData;
      if (response.data != null && response.data.toString().isNotEmpty) {
        try {
          parsedData = dart_convert.jsonDecode(response.data.toString());
        } catch (e) {
          parsedData = {};
        }
      } else {
        parsedData = {};
      }

      String? credential;

      if (isEld) {
        // ELD Server: استخراج الـ Token من الاستجابة JSON
        if (parsedData is Map<String, dynamic>) {
          final data = parsedData['data'] ?? parsedData;
          credential = data['token'] ?? data['access_token'] ?? data['session_token'];
        }
      } else {
        // Traccar Server: استخراج JSESSIONID من الـ Cookies
        final setCookieHeaders = response.headers.map['set-cookie'] ?? [];
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
      }

      if (credential == null || credential.isEmpty) {
        throw const ServerException(message: 'Missing session credential from server', arabicMessage: 'بيانات الجلسة مفقودة من الخادم');
      }

      dynamic userData = parsedData;

      if (userData is Map<String, dynamic> && userData.containsKey('data') && userData['status'] == true) {
        userData = userData['data'];
      }

      if (userData is! Map<String, dynamic>) {
        userData = {};
      }

      return AuthSession.create(
        serverOrigin: baseUrl,
        sessionCredential: credential,
        userMetadata: userData,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
        throw const ServerException(message: 'Invalid email or password', arabicMessage: 'البريد الإلكتروني أو كلمة المرور غير صحيحة', statusCode: 401);
      }
      final errorDetails = e.message ?? e.error?.toString() ?? e.type.toString();
      throw ServerException(message: 'Network error: $errorDetails', arabicMessage: 'خطأ في الشبكة: $errorDetails');
    }
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String serverUrl,
    required String backendType,
  }) async {
    final baseUrl = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
    final isEld = backendType == 'eld';

    try {
      final response = await _dio.post(
        '$baseUrl${_endpoints.register}',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
        options: Options(
          contentType: Headers.jsonContentType,
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
    required String backendType,
  }) async {
    try {
      final response = await _dio.get(
        '${currentSession.serverOrigin}${_endpoints.session}',
        options: Options(
          headers: backendType == 'eld' 
              ? {'Authorization': 'Bearer ${currentSession.sessionCredential}'}
              : {'Cookie': 'JSESSIONID=${currentSession.sessionCredential}'},
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 401 || response.statusCode == 403 || response.statusCode == 404) {
        throw const ServerException(message: 'Session expired or invalid', arabicMessage: 'الجلسة منتهية أو غير صالحة', statusCode: 401);
      } else if (response.statusCode != 200) {
        throw ServerException(message: 'Server error: ${response.statusCode}', arabicMessage: 'خطأ في الخادم', statusCode: response.statusCode);
      }

      dynamic userData = response.data;
      if (userData is Map<String, dynamic> && userData.containsKey('data') && userData['status'] == true) {
        userData = userData['data'];
      }

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
    required String backendType,
  }) async {
    final isEld = backendType == 'eld';
    try {
      await _dio.request(
        '${currentSession.serverOrigin}${_endpoints.logout}',
        options: Options(
          method: _endpoints.logoutMethod,
          headers: isEld
              ? {'Authorization': 'Bearer ${currentSession.sessionCredential}'}
              : {'Cookie': 'JSESSIONID=${currentSession.sessionCredential}'},
          followRedirects: false,
          validateStatus: (status) => true,
        ),
      );
    } catch (e) {
      // الفشل في إنهاء الجلسة من الخادم (بسبب الشبكة مثلاً) لا يجب أن يمنع تسجيل الخروج محلياً
    }
  }
}

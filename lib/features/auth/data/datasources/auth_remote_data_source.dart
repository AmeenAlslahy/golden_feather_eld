import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/exception.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/auth_session.dart';
import '../models/auth_session_dto.dart';
import '../../../../features/account/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  /// يقوم بتسجيل الدخول وإنشاء جلسة
  Future<AuthSessionDto> login({
    required String email,
    required String password,
    required String serverUrl,
    required String backendType,
  });

  /// يتحقق من صحة الجلسة الحالية
  Future<AuthSessionDto> validateSession({
    required AuthSessionDto currentSession,
    required String backendType,
  });

  /// ينهي الجلسة من الخادم
  Future<void> logout({
    required AuthSessionDto currentSession,
    required String backendType,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;
  final ApiEndpoints _endpoints;

  AuthRemoteDataSourceImpl(this._apiClient, this._endpoints);

  @override
  Future<AuthSessionDto> login({
    required String email,
    required String password,
    required String serverUrl,
    required String backendType,
  }) async {
    final baseUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    final isEld = backendType == 'eld';

    final response = await _apiClient.post(
      '$baseUrl${_endpoints.session}',
      data: isEld
          ? {'email': email, 'password': password}
          : {'email': email, 'password': password},
      options: Options(
        contentType: isEld
            ? Headers.jsonContentType
            : Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
        followRedirects: false,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.code == 401 || response.code == 400 || response.code == 403 || response.code == 404) {
      throw UnauthorizedException(statusCode: response.code);
    } else if (response.code != 200 && response.code != 201) {
      throw ServerException(
          message: 'Server error: ${response.code}', statusCode: response.code);
    }

    dynamic parsedData = response.data;
    if (parsedData == null && response.headers != null) {
        parsedData = {};
    }

    String? credential;

    if (isEld) {
      if (parsedData is Map<String, dynamic>) {
        final data = parsedData['data'] ?? parsedData;
        credential =
            data['token'] ?? data['access_token'] ?? data['session_token'];
      }
    } else {
      final headersMap = response.headers?.map;
      if (headersMap != null) {
        final setCookieHeaders = headersMap['set-cookie'] ?? [];
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
    }

    if (credential == null || credential.isEmpty) {
      throw const ServerException(
          message: 'Missing session credential from server');
    }

    dynamic userData = parsedData;
    if (userData is Map<String, dynamic> &&
        userData.containsKey('data') &&
        userData['status'] == true) {
      userData = userData['data'];
    }

    if (userData is! Map<String, dynamic>) {
      userData = {};
    }

    final userModel = UserModel.fromMetadata(userData, defaultEmail: email);

    return AuthSessionDto.create(
      serverOrigin: baseUrl,
      sessionCredential: credential,
      userModel: userModel,
    );
  }

  @override
  Future<AuthSessionDto> validateSession({
    required AuthSessionDto currentSession,
    required String backendType,
  }) async {
    final response = await _apiClient.get(
      '${currentSession.serverOrigin}${_endpoints.session}',
      options: Options(
        headers: backendType == 'eld'
            ? {'Authorization': 'Bearer ${currentSession.sessionCredential}'}
            : {'Cookie': 'JSESSIONID=${currentSession.sessionCredential}'},
        followRedirects: false,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.code == 401 ||
        response.code == 403 ||
        response.code == 404) {
      throw UnauthorizedException(statusCode: response.code);
    } else if (response.code != 200) {
      throw ServerException(
          message: 'Server error: ${response.code}', statusCode: response.code);
    }

    dynamic userData = response.data;
    if (userData is Map<String, dynamic> &&
        userData.containsKey('data') &&
        userData['status'] == true) {
      userData = userData['data'];
    }

    if (userData is! Map<String, dynamic>) {
      throw const ServerException(message: 'Invalid user payload format');
    }

    final userModel = UserModel.fromMetadata(userData);

    return AuthSessionDto.create(
      serverOrigin: currentSession.serverOrigin,
      sessionCredential: currentSession.sessionCredential,
      userModel: userModel,
    );
  }

  @override
  Future<void> logout({
    required AuthSessionDto currentSession,
    required String backendType,
  }) async {
    final isEld = backendType == 'eld';
    try {
      final options = Options(
        method: _endpoints.logoutMethod,
        headers: isEld
            ? {'Authorization': 'Bearer ${currentSession.sessionCredential}'}
            : {'Cookie': 'JSESSIONID=${currentSession.sessionCredential}'},
        followRedirects: false,
        validateStatus: (status) => true,
      );

      if (_endpoints.logoutMethod.toUpperCase() == 'POST') {
          await _apiClient.post('${currentSession.serverOrigin}${_endpoints.logout}', options: options);
      } else if (_endpoints.logoutMethod.toUpperCase() == 'DELETE') {
          await _apiClient.delete('${currentSession.serverOrigin}${_endpoints.logout}', options: options);
      } else {
          await _apiClient.get('${currentSession.serverOrigin}${_endpoints.logout}', options: options);
      }
    } catch (e) {
      // الفشل في إنهاء الجلسة من الخادم (بسبب الشبكة مثلاً) لا يجب أن يمنع تسجيل الخروج محلياً
    }
  }
}

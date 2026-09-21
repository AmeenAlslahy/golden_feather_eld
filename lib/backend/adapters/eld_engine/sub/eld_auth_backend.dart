import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/result/result.dart';
import '../../../../core/error/app_error.dart';
import '../../../contracts/auth_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';
import '../../../http/error_mapper.dart';
import '../../../http/eld_endpoints.dart';

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
      final isEld = backendType == 'eld';

      final response = await _apiClient.dio.post(
        '$baseUrl/api${EldEndpoints.session}',
        data: {'email': identifier, 'password': password},
        options: Options(
          contentType: isEld ? 'application/json' : 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 401 || response.statusCode == 400 || response.statusCode == 403 || response.statusCode == 404) {
         return err(ServerError(code: 'unauthorized', context: {'statusCode': response.statusCode}));
      } else if (response.statusCode != 200 && response.statusCode != 201) {
         return err(ServerError(code: 'server_error', context: {'statusCode': response.statusCode}));
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
      if (isEld) {
        if (parsedData is Map<String, dynamic>) {
          final data = parsedData['data'] ?? parsedData;
          credential = data['token'] ?? data['access_token'] ?? data['session_token'];
        }
      } else {
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
      }

      if (credential == null || credential.isEmpty) {
        return err(const ServerError(code: 'missing_credential'));
      }

      dynamic userData = parsedData;
      if (userData is Map<String, dynamic> && userData.containsKey('data') && userData['status'] == true) {
        userData = userData['data'];
      }
      if (userData is! Map<String, dynamic>) {
        userData = {};
      }

      return ok({
        'credential': credential,
        'user': userData,
        'serverOrigin': baseUrl,
      });
    } on DioException catch (e) {
      return err(mapDioException(e));
    } catch (e, st) {
      return err(UnknownError(code: 'login_error', cause: e, stackTrace: st));
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
        '$serverOrigin/api${EldEndpoints.session}',
        options: Options(
          headers: backendType == 'eld'
              ? {'Authorization': 'Bearer $sessionCredential'}
              : {'Cookie': 'JSESSIONID=$sessionCredential'},
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 401 || response.statusCode == 403 || response.statusCode == 404) {
         return err(ServerError(code: 'unauthorized', context: {'statusCode': response.statusCode}));
      } else if (response.statusCode != 200) {
         return err(ServerError(code: 'server_error', context: {'statusCode': response.statusCode}));
      }

      dynamic userData = response.data;
      if (userData is Map<String, dynamic> && userData.containsKey('data') && userData['status'] == true) {
        userData = userData['data'];
      }
      if (userData is! Map<String, dynamic>) {
        return err(const ServerError(code: 'invalid_payload'));
      }

      return ok({
        'credential': sessionCredential,
        'user': userData,
        'serverOrigin': serverOrigin,
      });
    } on DioException catch (e) {
      return err(mapDioException(e));
    } catch (e, st) {
      return err(UnknownError(code: 'validate_session_error', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<void>> logout({
    required String serverOrigin,
    required String sessionCredential,
    required String backendType,
  }) async {
    try {
      final isEld = backendType == 'eld';
      final options = Options(
        headers: isEld
            ? {'Authorization': 'Bearer $sessionCredential'}
            : {'Cookie': 'JSESSIONID=$sessionCredential'},
        followRedirects: false,
        validateStatus: (status) => true,
      );
      
      // Defaulting to DELETE for logout
      await _apiClient.dio.delete('$serverOrigin/api${EldEndpoints.session}', options: options);
      return ok(null);
    } catch (e) {
       // Fail gracefully
       return ok(null);
    }
  }
}

import 'package:dio/dio.dart';
import '../../../core/utils/logger.dart';

class RequestLogger extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.debug('🌐 Request: ${options.method} ${options.uri}');

    // Log headers safely
    if (options.headers.isNotEmpty) {
      AppLogger.debug('🏷️ Headers: ${_redactSensitiveData(options.headers)}');
    }

    if (options.data != null) {
      AppLogger.debug('📦 Data: ${_redactSensitiveData(options.data)}');
    }
    super.onRequest(options, handler);
  }

  dynamic _redactSensitiveData(dynamic data) {
    const sensitiveKeys = {
      'password',
      'pass',
      'token',
      'access_token',
      'refresh_token',
      'authorization',
      'cookie',
      'set-cookie',
      'session',
      'jsessionid',
      'secret',
      'api_key',
      'credential',
      'auth',
      'bearer'
    };

    if (data is Map) {
      final redacted = {};
      for (final key in data.keys) {
        final keyStr = key.toString().toLowerCase();
        if (sensitiveKeys.any((sensitive) => keyStr.contains(sensitive))) {
          redacted[key] = '[REDACTED]';
        } else {
          redacted[key] = _redactSensitiveData(data[key]);
        }
      }
      return redacted;
    } else if (data is List) {
      return data.map((e) => _redactSensitiveData(e)).toList();
    }
    return data;
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.debug(
        '✅ Response [${response.statusCode}] ${response.requestOptions.uri}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.requestOptions.uri.path.contains('/unsupported/')) {
      // Suppress noisy error logging for unsupported endpoints on Demo server
      super.onError(err, handler);
      return;
    }

    final statusCode = err.response?.statusCode ?? 'N/A';
    final type = err.type.name;
    AppLogger.error('❌ Error [$statusCode] ($type) ${err.requestOptions.uri}');

    if (err.type == DioExceptionType.badResponse) {
      final serverMsg = err.response?.statusMessage;
      AppLogger.error(
          'Message: ${serverMsg ?? 'Server returned status code $statusCode'}');
    } else if (err.message != null && err.message!.isNotEmpty) {
      AppLogger.error('Message: ${err.message}');
    } else {
      AppLogger.error('Message: Connection failed or server unreachable');
    }

    if (err.response?.data != null) {
      final data = err.response?.data;
      if (data is String) {
        if (data.trim().startsWith('<html')) {
          final titleMatch =
              RegExp(r'<title>(.*?)</title>', caseSensitive: false)
                  .firstMatch(data);
          final title =
              titleMatch != null ? titleMatch.group(1) : 'HTML Error Page';
          AppLogger.error('Data: [Server responded with HTML page: $title]');
        } else {
          AppLogger.error(
              'Data: ${data.length > 500 ? '${data.substring(0, 500)}...' : data}');
        }
      } else {
        AppLogger.error('Data: $data');
      }
    }
    super.onError(err, handler);
  }
}

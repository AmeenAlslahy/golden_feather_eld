import 'package:dio/dio.dart';
import '../utils/logger.dart';

class RequestLogger extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.debug('🌐 Request: ${options.method} ${options.uri}');
    if (options.data != null) {
      AppLogger.debug('📦 Data: ${options.data}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.debug('✅ Response [${response.statusCode}] ${response.requestOptions.uri}');
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
      AppLogger.error('Message: ${serverMsg ?? 'Server returned status code $statusCode'}');
    } else if (err.message != null && err.message!.isNotEmpty) {
      AppLogger.error('Message: ${err.message}');
    } else {
      AppLogger.error('Message: Connection failed or server unreachable');
    }
    
    if (err.response?.data != null) {
      final data = err.response?.data;
      if (data is String) {
        if (data.trim().startsWith('<html')) {
           final titleMatch = RegExp(r'<title>(.*?)</title>', caseSensitive: false).firstMatch(data);
           final title = titleMatch != null ? titleMatch.group(1) : 'HTML Error Page';
           AppLogger.error('Data: [Server responded with HTML page: $title]');
        } else {
           AppLogger.error('Data: ${data.length > 500 ? '${data.substring(0, 500)}...' : data}');
        }
      } else {
        AppLogger.error('Data: $data');
      }
    }
    super.onError(err, handler);
  }
}

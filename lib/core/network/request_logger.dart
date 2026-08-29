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
    final statusCode = err.response?.statusCode ?? 'N/A';
    final type = err.type.name;
    AppLogger.error('❌ Error [$statusCode] ($type) ${err.requestOptions.uri}');
    
    if (err.message != null && err.message!.isNotEmpty) {
      AppLogger.error('Message: ${err.message}');
    } else {
      AppLogger.error('Message: Connection failed or server unreachable');
    }
    
    if (err.response?.data != null) {
      AppLogger.error('Data: ${err.response?.data}');
    }
    super.onError(err, handler);
  }
}

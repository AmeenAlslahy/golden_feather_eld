import 'dart:convert';
import 'package:dio/dio.dart';
import '../error/exception.dart';
import 'api_config.dart';
import 'api_response.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({required ApiConfig config, required Dio dio}) : _dio = dio {
    _dio.options.baseUrl = config.baseUrl;
    _dio.options.connectTimeout = config.connectTimeout;
    _dio.options.receiveTimeout = config.receiveTimeout;

    // Default headers
    _dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  Future<ApiResponse<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters,
      Options? options,
      T Function(dynamic)? fromJsonT}) async {
    try {
      final response = await _dio.get(path,
          queryParameters: queryParameters, options: options);
      return _processResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ApiResponse<T>> post<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      T Function(dynamic)? fromJsonT}) async {
    try {
      final response = await _dio.post(path,
          data: data, queryParameters: queryParameters, options: options);
      return _processResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ApiResponse<T>> put<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      T Function(dynamic)? fromJsonT}) async {
    try {
      final response = await _dio.put(path,
          data: data, queryParameters: queryParameters, options: options);
      return _processResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ApiResponse<T>> delete<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      T Function(dynamic)? fromJsonT}) async {
    try {
      final response = await _dio.delete(path,
          data: data, queryParameters: queryParameters, options: options);
      return _processResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String> downloadFile(String path, String savePath,
      {Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      await _dio.download(path, savePath,
          queryParameters: queryParameters, options: options);
      return savePath;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ApiResponse<T> _processResponse<T>(
      Response response, T Function(dynamic)? fromJsonT) {
    var rawData = response.data;

    // Decode String to JSON if possible
    if (rawData is String && rawData.isNotEmpty) {
      try {
        rawData = jsonDecode(rawData);
      } catch (_) {
        // Not valid JSON
      }
    }

    if (rawData is Map<String, dynamic>) {
      // Check if it matches our standard API response format
      if (rawData.containsKey('status') && rawData.containsKey('code')) {
        final apiResp = ApiResponse.fromJson(rawData, fromJsonT);
        return ApiResponse<T>(
          code: apiResp.code,
          status: apiResp.status,
          data: apiResp.data,
          message: apiResp.message,
          error: apiResp.error,
          headers: response.headers,
        );
      }
    }

    // Safely cast to T
    T? finalData;
    if (fromJsonT != null) {
      finalData = fromJsonT(rawData);
    } else {
      if (rawData is T) {
        finalData = rawData;
      } else {
        finalData = null; // Prevent CastError
      }
    }

    // Wrap raw response
    return ApiResponse<T>(
      code: response.statusCode ?? 200,
      status: (response.statusCode ?? 200) >= 200 &&
          (response.statusCode ?? 200) < 300,
      data: finalData,
      headers: response.headers,
    );
  }

  Exception _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const OfflineException();
    }

    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return UnauthorizedException(statusCode: statusCode);
      }

      final data = e.response!.data;
      String message = 'Unknown server error';
      if (data is Map<String, dynamic>) {
        message =
            data['message']?.toString() ?? data['error']?.toString() ?? message;
      } else if (data is String) {
        if (statusCode == 404) {
          message = 'الخدمة غير متوفرة حالياً (404)';
        } else if (data.contains('<html') || data.contains('Exception:')) {
          message = 'حدث خطأ داخلي في الخادم ($statusCode)';
        } else {
          message = data.length > 100 ? '${data.substring(0, 100)}...' : data;
        }
      }

      return ServerException(
        statusCode: statusCode,
        message: message,
        // Can be localized later
      );
    }

    String message = 'فشل الاتصال بالخادم';
    if (e.type == DioExceptionType.cancel) {
      message = 'تم إلغاء الطلب';
    }

    return ServerException(
      message: message,
    );
  }
}

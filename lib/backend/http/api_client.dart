/// Thin HTTP client for the ELD backend.
///
/// Responsibilities:
///   - Execute HTTP requests.
///   - Normalize responses via [ApiResponse].
///   - Map transport errors to [AppError] via [mapDioException].
///
/// **Not** responsible for:
///   - Auth token injection (see interceptors).
///   - Retry logic (see future RetryInterceptor).
///   - Domain mapping (see adapters).
///   - Response caching.
library;


import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart' as fp;

import '../../core/error/app_error.dart';
import '../../core/result/result.dart';
import 'api_config.dart';
import 'api_response.dart';
import 'error_mapper.dart';
import 'lenient_json_transformer.dart';

class ApiClient {
  final Dio _dio;
  final ApiConfig _config;

  ApiClient({required ApiConfig config, Dio? dio})
      : _config = config.normalized(),
        _dio = dio ?? Dio() {
    _dio.transformer = LenientJsonTransformer();
    _dio.options
      ..baseUrl = _config.baseUrl
      ..connectTimeout = _config.connectTimeout
      ..receiveTimeout = _config.receiveTimeout
      ..sendTimeout = _config.sendTimeout
      ..headers = Map.of(_config.defaultHeaders)
      ..responseType = ResponseType.json;

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: true,
        // لا نسجّل رؤوس الطلب: قد تحمل Cookie JSESSIONID (مهلة الجلسة).
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ));
    }
  }

  /// Exposes the raw [Dio] instance for advanced use cases
  /// (interceptor installation, custom adapters for tests).
  Dio get dio => _dio;

  // ==========================================================================
  // JSON methods
  // ==========================================================================

  Future<Result<ApiResponse<T>>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
  }) {
    return _execute<T>(
      () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: _buildOptions(headers: headers),
      ),
      parser: parser,
    );
  }

  Future<Result<ApiResponse<T>>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    ResponseType? responseType,
    T Function(dynamic)? parser,
  }) {
    return _execute<T>(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(headers: headers, responseType: responseType),
      ),
      parser: parser,
    );
  }

  Future<Result<ApiResponse<T>>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
  }) {
    return _execute<T>(
      () => _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(headers: headers),
      ),
      parser: parser,
    );
  }

  Future<Result<ApiResponse<T>>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
  }) {
    return _execute<T>(
      () => _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(headers: headers),
      ),
      parser: parser,
    );
  }

  // ==========================================================================
  // Multipart upload
  // ==========================================================================

  /// Uploads a file via `multipart/form-data`.
  ///
  /// [fileBytes] is the raw file content.
  /// [fieldName] is the form field name (usually `document` or `file`).
  /// [fileName] is the name presented to the server.
  /// [additionalFields] are extra form fields (e.g. `type`, `metadata`).
  Future<Result<ApiResponse<T>>> uploadFile<T>(
    String path, {
    required Uint8List fileBytes,
    required String fieldName,
    required String fileName,
    Map<String, String>? additionalFields,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
  }) {
    return _execute<T>(
      () async {
        final formData = FormData.fromMap({
          fieldName: MultipartFile.fromBytes(
            fileBytes,
            filename: fileName,
          ),
          ...?additionalFields,
        });

        return _dio.post<dynamic>(
          path,
          data: formData,
          options: _buildOptions(
            headers: headers,
            contentType: 'multipart/form-data',
          ),
        );
      },
      parser: parser,
    );
  }

  // ==========================================================================
  // Binary download
  // ==========================================================================

  /// Downloads a file and returns its raw bytes.
  Future<Result<Uint8List>> download(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        queryParameters: queryParameters,
        options: _buildOptions(
          headers: headers,
          responseType: ResponseType.bytes,
        ),
      );

      final bytes = response.data;
      if (bytes == null) {
        return fp.Left(ServerError(
          code: 'server.emptyBinaryResponse',
          context: {'uri': response.requestOptions.uri.toString()},
        ));
      }

      return fp.Right(Uint8List.fromList(bytes));
    } on DioException catch (e) {
      return fp.Left(mapDioException(e));
    } catch (e, st) {
      return fp.Left(UnknownError(
        code: 'client.downloadUnexpected',
        cause: e,
        stackTrace: st,
      ));
    }
  }

  // ==========================================================================
  // Internals
  // ==========================================================================

  Options _buildOptions({
    Map<String, String>? headers,
    String? contentType,
    ResponseType? responseType,
  }) {
    return Options(
      headers: headers,
      contentType: contentType,
      responseType: responseType,
    );
  }

  Future<Result<ApiResponse<T>>> _execute<T>(
    Future<Response<dynamic>> Function() request, {
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await request();

      final apiResponse = ApiResponse.fromBody<T>(
        statusCode: response.statusCode ?? 0,
        rawBody: response.data,
        parser: parser,
      );

      return fp.Right(apiResponse);
    } on DioException catch (e) {
      return fp.Left(mapDioException(e));
    } catch (e, st) {
      return fp.Left(UnknownError(
        code: 'client.requestUnexpected',
        cause: e,
        stackTrace: st,
      ));
    }
  }
}

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


import 'dart:typed_data';
import 'package:dio/dio.dart';
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

  /// Max automatic retries for idempotent requests (GET) after a
  /// transient network failure (timeout / connection error). Mutating
  /// methods (POST/PUT/DELETE/uploads) are never retried — a retry could
  /// repeat a side effect the server already applied.
  final int maxRetries;

  /// Base delay before the first retry; doubles with each further attempt.
  final Duration retryBackoff;

  ApiClient({
    required ApiConfig config,
    Dio? dio,
    this.maxRetries = 2,
    this.retryBackoff = const Duration(milliseconds: 400),
  })  : _config = config.normalized(),
        _dio = dio ?? Dio() {
    _dio.transformer = LenientJsonTransformer();
    _dio.options
      ..baseUrl = _config.baseUrl
      ..connectTimeout = _config.connectTimeout
      ..receiveTimeout = _config.receiveTimeout
      ..sendTimeout = _config.sendTimeout
      ..headers = Map.of(_config.defaultHeaders)
      ..responseType = ResponseType.json;

    // Logging lives in one interceptor (`RequestLogger`, debug only, redacted).
    // The former `LogInterceptor(requestBody: true, responseBody: true)` was a
    // second logger that printed the login body and every response twice.
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
    CancelToken? cancelToken,
    T Function(dynamic)? parser,
  }) {
    return _execute<T>(
      () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: _buildOptions(headers: headers),
        cancelToken: cancelToken,
      ),
      parser: parser,
      // GET is idempotent → eligible for transient-failure retries.
      idempotent: true,
      cancelToken: cancelToken,
    );
  }

  Future<Result<ApiResponse<T>>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    ResponseType? responseType,
    CancelToken? cancelToken,
    T Function(dynamic)? parser,
  }) {
    return _execute<T>(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(headers: headers, responseType: responseType),
        cancelToken: cancelToken,
      ),
      parser: parser,
      cancelToken: cancelToken,
    );
  }

  Future<Result<ApiResponse<T>>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    T Function(dynamic)? parser,
  }) {
    return _execute<T>(
      () => _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(headers: headers),
        cancelToken: cancelToken,
      ),
      parser: parser,
      cancelToken: cancelToken,
    );
  }

  Future<Result<ApiResponse<T>>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    T Function(dynamic)? parser,
  }) {
    return _execute<T>(
      () => _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(headers: headers),
        cancelToken: cancelToken,
      ),
      parser: parser,
      cancelToken: cancelToken,
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
    CancelToken? cancelToken,
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
          cancelToken: cancelToken,
        );
      },
      parser: parser,
      cancelToken: cancelToken,
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
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        queryParameters: queryParameters,
        options: _buildOptions(
          headers: headers,
          responseType: ResponseType.bytes,
        ),
        cancelToken: cancelToken,
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
    bool idempotent = false,
    CancelToken? cancelToken,
  }) async {
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        final response = await request();

        final apiResponse = ApiResponse.fromBody<T>(
          statusCode: response.statusCode ?? 0,
          rawBody: response.data,
          parser: parser,
        );

        return fp.Right(apiResponse);
      } on DioException catch (e) {
        // Retry only idempotent requests after a transient transport
        // failure, up to [maxRetries] times, and never once the caller
        // has cancelled the request.
        final transient = _isTransient(e);
        if (!idempotent ||
            !transient ||
            attempt > maxRetries ||
            (cancelToken?.isCancelled ?? false)) {
          return fp.Left(mapDioException(e));
        }
        if (retryBackoff > Duration.zero) {
          await Future<void>.delayed(retryBackoff * attempt);
        }
      } catch (e, st) {
        return fp.Left(UnknownError(
          code: 'client.requestUnexpected',
          cause: e,
          stackTrace: st,
        ));
      }
    }
  }

  /// Whether a [DioException] is a transient transport failure worth
  /// retrying for an idempotent request. Server decisions (4xx/5xx) and
  /// cancellations are never retried.
  bool _isTransient(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        return false;
    }
  }
}

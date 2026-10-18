/// Unified HTTP response wrapper.
///
/// The ELD backend returns responses in **three formats**:
///
///   1. **Enveloped (legacy):**
///      ```json
///      {
///        "code": 200,
///        "status": true,
///        "data": { ... },
///        "message": "...",
///        "error": null
///      }
///      ```
///
///   2. **Enveloped (new):**
///      ```json
///      {
///        "success": true,
///        "data": { ... },
///        "pagination": {
///          "page": 0, "size": 20, "totalElements": 45,
///          "totalPages": 3, "hasNext": true, "hasPrevious": false
///        },
///        "errors": [],
///        "requestId": "..."
///      }
///      ```
///
///   3. **Direct** (no envelope):
///      ```json
///      { "id": 42, "name": "..." }
///      ```
///
/// [ApiResponse] normalizes all three into a single representation.
library;

/// Single field error from the unified envelope (`GET /daily-logs` spec).
class ApiFieldError {
  final String field;
  final String message;
  final String? code;

  const ApiFieldError({
    required this.field,
    required this.message,
    this.code,
  });

  static ApiFieldError? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final field = raw['field'];
    final message = raw['message'];
    if (field is! String || message is! String) return null;
    final code = raw['code'];
    return ApiFieldError(
      field: field,
      message: message,
      code: code is String ? code : null,
    );
  }

  @override
  String toString() => code == null ? '$field: $message' : '$field ($code): $message';
}

/// Pagination metadata from the unified envelope.
class PaginationInfo {
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  const PaginationInfo({
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  static PaginationInfo? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final page = raw['page'];
    if (page is! int) return null;
    final size = raw['size'];
    final totalElements = raw['totalElements'];
    final totalPages = raw['totalPages'];
    return PaginationInfo(
      page: page,
      size: size is int ? size : 0,
      totalElements: totalElements is int ? totalElements : 0,
      totalPages: totalPages is int ? totalPages : 0,
      hasNext: raw['hasNext'] == true,
      hasPrevious: raw['hasPrevious'] == true,
    );
  }

  @override
  String toString() =>
      'PaginationInfo(page: $page, size: $size, totalElements: $totalElements, '
      'totalPages: $totalPages, hasNext: $hasNext, hasPrevious: $hasPrevious)';
}

class ApiResponse<T> {
  /// HTTP status code (always present).
  final int statusCode;

  /// Unwrapped payload.
  ///
  /// For enveloped responses, this is `data`.
  /// For direct responses, this is the raw body.
  final T? data;

  /// Server-provided message (from envelope, if present).
  final String? message;

  /// Server-provided error code (from envelope, if present).
  final String? errorCode;

  /// Whether the response indicates success.
  ///
  /// `true` when:
  ///   - HTTP status is 2xx, **and**
  ///   - Envelope `status` / `success` is `true` (if envelope present).
  final bool isSuccess;

  /// Raw response body (for debugging / custom parsing).
  final Object? rawBody;

  /// Field-level validation errors from the unified envelope (`errors[]`).
  final List<ApiFieldError> errors;

  /// Correlation id from the unified envelope (`requestId`). Include it in
  /// support reports / logs when contacting the backend team.
  final String? requestId;

  /// Pagination metadata from the unified envelope (`pagination`).
  final PaginationInfo? pagination;

  const ApiResponse({
    required this.statusCode,
    required this.isSuccess,
    this.data,
    this.message,
    this.errorCode,
    this.rawBody,
    this.errors = const [],
    this.requestId,
    this.pagination,
  });

  /// Returns a copy with [data] replaced.
  ApiResponse<R> withData<R>(R? newData) {
    return ApiResponse<R>(
      statusCode: statusCode,
      isSuccess: isSuccess,
      data: newData,
      message: message,
      errorCode: errorCode,
      rawBody: rawBody,
      errors: errors,
      requestId: requestId,
      pagination: pagination,
    );
  }

  /// Parses a raw response body and normalizes it.
  ///
  /// If [parser] is provided, it is applied to the unwrapped payload.
  /// Otherwise, the payload is returned as-is (requires `T` to be
  /// `dynamic`, `Map<String, dynamic>`, or `List<dynamic>`).
  static ApiResponse<T> fromBody<T>({
    required int statusCode,
    required Object? rawBody,
    T Function(dynamic)? parser,
  }) {
    final isEnvelope = _looksLikeEnvelope(rawBody);

    if (isEnvelope) {
      final map = rawBody as Map<String, dynamic>;
      final envelopeStatus = map['status'] ?? map['success'];
      final envelopeCode = map['code'];
      final envelopeMessage = map['message'];
      final envelopeError = map['error'];
      final payload = map['data'];

      final isSuccess = (statusCode >= 200 && statusCode < 300) &&
          (envelopeStatus == null || envelopeStatus == true);

      return ApiResponse<T>(
        statusCode: envelopeCode is int ? envelopeCode : statusCode,
        isSuccess: isSuccess,
        data: _parsePayload<T>(payload, parser),
        message: envelopeMessage is String ? envelopeMessage : null,
        errorCode: envelopeError is String ? envelopeError : null,
        rawBody: rawBody,
        errors: _parseErrors(map['errors']),
        requestId: map['requestId'] is String
            ? map['requestId'] as String
            : null,
        pagination: PaginationInfo.tryParse(map['pagination']),
      );
    }

    // Direct response: payload is the whole body.
    return ApiResponse<T>(
      statusCode: statusCode,
      isSuccess: statusCode >= 200 && statusCode < 300,
      data: _parsePayload<T>(rawBody, parser),
      rawBody: rawBody,
    );
  }

  /// An envelope must have BOTH `code` and `status` (legacy format),
  /// OR `success` combined with any envelope marker (new unified format:
  /// `data`, `message`, `errors` or `requestId` — the newer error envelope
  /// carries no `data`).
  ///
  /// This conservative check prevents false positives when a
  /// domain object legitimately has a `code` field (e.g. `DtcCode`).
  static bool _looksLikeEnvelope(Object? raw) {
    if (raw is! Map<String, dynamic>) return false;
    // Legacy format: { code, status, data, ... }
    if (raw.containsKey('code') && raw.containsKey('status')) return true;
    // New format: { success, data|message|errors|requestId, ... }
    if (raw.containsKey('success') &&
        (raw.containsKey('data') ||
            raw.containsKey('message') ||
            raw.containsKey('errors') ||
            raw.containsKey('requestId'))) {
      return true;
    }
    return false;
  }

  static List<ApiFieldError> _parseErrors(Object? raw) {
    if (raw is! List) return const [];
    final result = <ApiFieldError>[];
    for (final entry in raw) {
      final parsed = ApiFieldError.tryParse(entry);
      if (parsed != null) result.add(parsed);
    }
    return result;
  }

  static T? _parsePayload<T>(
    dynamic payload,
    T Function(dynamic)? parser,
  ) {
    if (payload == null) return null;

    if (parser != null) {
      return parser(payload);
    }

    if (payload is T) {
      return payload;
    }

    return null;
  }

  @override
  String toString() =>
      'ApiResponse<$T>(statusCode: $statusCode, isSuccess: $isSuccess, '
      'data: $data, message: $message)';
}

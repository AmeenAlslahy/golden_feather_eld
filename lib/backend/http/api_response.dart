/// Unified HTTP response wrapper.
///
/// The ELD backend returns responses in **two formats**:
///
///   1. **Enveloped** (legacy endpoints):
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
///   2. **Direct** (newer endpoints):
///      ```json
///      { "id": 42, "name": "..." }
///      ```
///
/// [ApiResponse] normalizes both into a single representation.
library;

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
  ///   - Envelope `status` is `true` (if envelope present).
  final bool isSuccess;

  /// Raw response body (for debugging / custom parsing).
  final Object? rawBody;

  const ApiResponse({
    required this.statusCode,
    required this.isSuccess,
    this.data,
    this.message,
    this.errorCode,
    this.rawBody,
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
      final envelopeStatus = map['status'];
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

  /// An envelope must have BOTH `code` and `status`.
  ///
  /// This conservative check prevents false positives when a
  /// domain object legitimately has a `code` field (e.g. `DtcCode`).
  static bool _looksLikeEnvelope(Object? raw) {
    return raw is Map<String, dynamic> &&
        raw.containsKey('code') &&
        raw.containsKey('status');
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

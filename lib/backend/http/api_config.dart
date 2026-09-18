/// HTTP configuration for the ELD backend.
///
/// This is a **pure value object**. It carries no business logic.
/// It is created by the composition root and passed to [ApiClient].
///
/// **Rule:** The base URL must be user-configured. Never hardcoded.
library;

class ApiConfig {
  /// Base URL including the `/api` path.
  ///
  /// Examples:
  ///   - `https://eld.example.com/api`
  ///   - `https://account.now-ye.com/api`
  ///
  /// **No trailing slash.**
  final String baseUrl;

  /// Timeout for establishing a TCP connection.
  final Duration connectTimeout;

  /// Timeout for receiving data after a request is sent.
  final Duration receiveTimeout;

  /// Timeout for sending data (e.g. uploads).
  final Duration sendTimeout;

  /// Headers sent with every request.
  ///
  /// `Content-Type` is set per-request (JSON or multipart),
  /// so it is **not** included here.
  final Map<String, String> defaultHeaders;

  const ApiConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
    this.defaultHeaders = const {
      'Accept': 'application/json',
    },
  });

  /// Whether the config is usable.
  ///
  /// A config with an empty [baseUrl] is invalid and must not
  /// be passed to [ApiClient].
  bool get isValid => baseUrl.isNotEmpty && Uri.tryParse(baseUrl) != null;

  /// Returns a normalized copy:
  ///   - `baseUrl` has no trailing slash.
  ///   - `baseUrl` has an `https` scheme if none was provided.
  ApiConfig normalized() {
    var normalizedUrl = baseUrl.trim();

    // Ensure scheme
    if (!normalizedUrl.contains('://')) {
      normalizedUrl = 'https://$normalizedUrl';
    }

    // Remove trailing slash(es)
    while (normalizedUrl.endsWith('/')) {
      normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
    }

    return ApiConfig(
      baseUrl: normalizedUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      defaultHeaders: defaultHeaders,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiConfig &&
          runtimeType == other.runtimeType &&
          baseUrl == other.baseUrl &&
          connectTimeout == other.connectTimeout &&
          receiveTimeout == other.receiveTimeout &&
          sendTimeout == other.sendTimeout;

  @override
  int get hashCode => Object.hash(
        baseUrl,
        connectTimeout,
        receiveTimeout,
        sendTimeout,
      );

  @override
  String toString() =>
      'ApiConfig(baseUrl: $baseUrl, '
      'timeouts: connect=$connectTimeout, '
      'receive=$receiveTimeout, send=$sendTimeout)';
}

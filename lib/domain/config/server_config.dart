import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_config.freezed.dart';

/// Which backend implementation the client should target.
enum BackendType {
  eld('eld'),
  traccar('traccar');

  const BackendType(this.wire);

  final String wire;

  static BackendType fromWire(String? value) {
    final lower = value?.toLowerCase() ?? '';
    return BackendType.values.firstWhere(
      (t) => t.wire == lower,
      orElse: () => BackendType.eld,
    );
  }
}

/// Configuration for connecting to a remote backend.
///
/// **Stored in `SecureStoragePort`** because the URL may include
/// a tenant token in some deployments.
@freezed
abstract class ServerConfig with _$ServerConfig {
  const ServerConfig._();

  const factory ServerConfig({
    /// Full base URL including the `/api` path.
    /// **No trailing slash.**
    required String baseUrl,

    required BackendType backendType,

    /// When the URL was last verified via a probe.
    required DateTime lastTestedAt,

    /// Whether the last probe succeeded.
    required bool isVerified,
  }) = _ServerConfig;

  /// Whether this config is usable for real requests.
  bool get isUsable => isVerified && baseUrl.isNotEmpty;

  /// Normalizes a URL: trims, ensures scheme, removes trailing slashes.
  static String normalizeUrl(String url) {
    var normalized = url.trim();
    if (!normalized.contains('://')) {
      normalized = 'https://$normalized';
    }
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  /// Creates a config from a raw URL, not yet verified.
  factory ServerConfig.unverified({
    required String baseUrl,
    BackendType backendType = BackendType.eld,
  }) {
    return ServerConfig(
      baseUrl: normalizeUrl(baseUrl),
      backendType: backendType,
      lastTestedAt: DateTime.fromMillisecondsSinceEpoch(0),
      isVerified: false,
    );
  }

  /// Creates a verified config.
  factory ServerConfig.verified({
    required String baseUrl,
    required BackendType backendType,
  }) {
    return ServerConfig(
      baseUrl: normalizeUrl(baseUrl),
      backendType: backendType,
      lastTestedAt: DateTime.now().toUtc(),
      isVerified: true,
    );
  }
}

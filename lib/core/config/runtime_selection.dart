import 'app_environment.dart';

/// The one rule for mock-versus-live and the server host.
///
/// Environment name comes only from `APP_ENV`, then `TRACCAR_ENVIRONMENT`,
/// then `development`. A saved preference cannot turn production or staging
/// into mock. In development, a saved `backendType` of `mock` is an explicit
/// developer override.
///
/// Server host: a non-empty saved URL is the settings override. Otherwise the
/// build `API_BASE_URL` is used. `https://snsoft.cloud` is only the last resort
/// when both are empty.
class RuntimeBackendChoice {
  final bool useMock;
  final String serverUrl;

  const RuntimeBackendChoice({
    required this.useMock,
    required this.serverUrl,
  });
}

const String fallbackServerOrigin = 'https://snsoft.cloud';

RuntimeBackendChoice resolveRuntimeBackend({
  required AppEnvironment environment,
  required String buildBaseUrl,
  required String savedServerUrl,
  required String savedBackendType,
}) {
  final useMock = environment == AppEnvironment.mock ||
      (environment == AppEnvironment.development && savedBackendType == 'mock');

  final saved = savedServerUrl.trim();
  final build = buildBaseUrl.trim();
  final serverUrl = saved.isNotEmpty
      ? saved
      : (build.isNotEmpty ? build : fallbackServerOrigin);

  return RuntimeBackendChoice(useMock: useMock, serverUrl: serverUrl);
}

/// `BACKEND_TYPE`, then an explicit saved config type, then the stored type.
/// A host name is not a backend type.
String resolveBackendType({
  required String? configuredType,
  required String? savedConfigType,
  required String storedType,
}) {
  final configured = _knownBackendType(configuredType);
  if (configured != null) return configured;
  final saved = _knownBackendType(savedConfigType);
  if (saved != null) return saved;
  return _knownBackendType(storedType) ?? 'traccar';
}

String? _knownBackendType(String? value) {
  final type = value?.trim().toLowerCase();
  if (type == 'eld' || type == 'traccar') return type;
  return null;
}

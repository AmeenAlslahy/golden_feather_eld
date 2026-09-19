import '../../core/result/result.dart';
import 'raw_json.dart';

abstract interface class AuthBackend {
  Future<Result<RawJson>> login({
    required String identifier,
    required String password,
    required String serverUrl,
    required String backendType,
  });

  Future<Result<RawJson>> validateSession({
    required String serverOrigin,
    required String sessionCredential,
    required String backendType,
  });

  Future<Result<void>> logout({
    required String serverOrigin,
    required String sessionCredential,
    required String backendType,
  });
}

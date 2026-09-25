import '../../../../core/result/result.dart';
import '../../../contracts/auth_backend.dart';
import '../../../contracts/raw_json.dart';

class MockAuthBackend implements AuthBackend {
  const MockAuthBackend();

  @override
  Future<Result<RawJson>> login({
    required String identifier,
    required String password,
    required String serverUrl,
    required String backendType,
  }) async {
    return ok({
      'credential': 'mock_token',
      'user': {'id': 1, 'name': 'Mock User'},
      'serverOrigin': serverUrl,
    });
  }

  @override
  Future<Result<RawJson>> validateSession({
    required String serverOrigin,
    required String sessionCredential,
    required String backendType,
  }) async {
    return ok({
      'credential': sessionCredential,
      'user': {'id': 1, 'name': 'Mock User'},
      'serverOrigin': serverOrigin,
    });
  }

  @override
  Future<Result<void>> logout({
    required String serverOrigin,
    required String sessionCredential,
    required String backendType,
  }) async {
    return ok(null);
  }

  @override
  Future<Result<void>> requestPasswordReset({
    required String email,
    required String serverUrl,
  }) async {
    return ok(null);
  }
}

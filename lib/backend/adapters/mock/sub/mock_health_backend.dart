import '../../../../core/result/result.dart';
import '../../../contracts/health_backend.dart';
import '../../../contracts/raw_json.dart';
import '../fixtures/health_fixtures.dart';

/// In-memory mock for [HealthBackend].
///
/// **Rule:** No network, no delays, deterministic output.
class MockHealthBackend implements HealthBackend {
  const MockHealthBackend();

  @override
  Future<Result<void>> checkLiveness() async {
    return ok(null);
  }

  @override
  Future<Result<RawJson>> checkDetailed() async {
    return ok(Map<String, dynamic>.from(healthDetailedFixture));
  }
}

import '../../../../core/result/result.dart';
import '../../../contracts/config_backend.dart';
import '../../../contracts/raw_json.dart';

/// In-memory mock for [ConfigBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class MockConfigBackend implements ConfigBackend {
  const MockConfigBackend();

  @override
  Future<Result<RawJson>> getConfig() =>
      throw UnimplementedError('MockConfigBackend.getConfig — Phase 2');

  @override
  Future<Result<RawJson>> getConfigRules() =>
      throw UnimplementedError('MockConfigBackend.getConfigRules — Phase 2');

  @override
  Future<Result<RawJson>> getSettings() =>
      throw UnimplementedError('MockConfigBackend.getSettings — Phase 2');
}

// ignore_for_file: unused_field, unused_import

import '../../../../core/result/result.dart';
import '../../../contracts/config_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';

/// ELD Engine implementation of [ConfigBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldConfigBackend implements ConfigBackend {
  final ApiClient _apiClient;

  const EldConfigBackend(this._apiClient);

  @override
  Future<Result<RawJson>> getConfig() =>
      throw UnimplementedError('EldConfigBackend.getConfig — Phase 2');

  @override
  Future<Result<RawJson>> getConfigRules() =>
      throw UnimplementedError('EldConfigBackend.getConfigRules — Phase 2');

  @override
  Future<Result<RawJson>> getSettings() =>
      throw UnimplementedError('EldConfigBackend.getSettings — Phase 2');
}

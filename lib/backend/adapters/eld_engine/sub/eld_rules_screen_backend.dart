// ignore_for_file: unused_field, unused_import

import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/rules_screen_backend.dart';
import '../../../http/api_client.dart';

/// ELD Engine implementation of [RulesScreenBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldRulesScreenBackend implements RulesScreenBackend {
  final ApiClient _apiClient;

  const EldRulesScreenBackend(this._apiClient);

  @override
  Future<Result<RawJson>> getRulesScreen({DriverId? driverId}) =>
      throw UnimplementedError('EldRulesScreenBackend.getRulesScreen — Phase 2');

  @override
  Future<Result<RawJson>> saveRulesScreen(RawJson settings) =>
      throw UnimplementedError('EldRulesScreenBackend.saveRulesScreen — Phase 2');
}

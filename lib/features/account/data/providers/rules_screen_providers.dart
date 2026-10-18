import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../application/usecases/update_rules_use_case.dart';
import '../datasources/rules_screen_local_cache.dart';
import '../repositories/rules_screen_repository.dart';

final rulesScreenLocalCacheProvider = Provider<RulesScreenLocalCache>((ref) {
  return PrefsRulesScreenLocalCache(ref.watch(localStorageProvider));
});

final rulesScreenRepositoryProvider = Provider<RulesScreenRepository>((ref) {
  return RulesScreenRepository(
    ref.watch(rulesScreenBackendProvider),
    ref.watch(rulesScreenLocalCacheProvider),
  );
});

final updateRulesUseCaseProvider = Provider<UpdateRulesUseCase>((ref) {
  return UpdateRulesUseCase(
    ref.watch(rulesScreenBackendProvider),
    ref.watch(localStorageProvider),
  );
});

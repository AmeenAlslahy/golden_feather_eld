import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/local_storage_service.dart';
import '../datasources/rules_screen_local_cache.dart';

final rulesScreenLocalCacheProvider = Provider<RulesScreenLocalCache>((ref) {
  return PrefsRulesScreenLocalCache(ref.watch(localStorageProvider));
});

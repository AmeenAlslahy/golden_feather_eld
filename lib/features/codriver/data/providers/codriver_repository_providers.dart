import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/contracts/driver_session_backend.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../sync/data/providers/sync_providers.dart';
import '../../domain/repositories/codriver_repository.dart';
import '../datasources/codriver_local_cache.dart';
import '../repositories/codriver_repository_impl.dart';

// --- DI: طبقة البيانات هي من تركّب مستودعها (المرحلة 3b) ---

final driverSessionBackendProviderAlias = Provider<DriverSessionBackend>((ref) {
  return ref.watch(driverSessionBackendProvider);
});

final coDriverLocalCacheProvider = Provider<CoDriverLocalCache>((ref) {
  return PrefsCoDriverLocalCache(ref.watch(localStorageProvider));
});

final coDriverRepositoryProvider = Provider<CoDriverRepository>((ref) {
  return CoDriverRepositoryImpl(
    driverSessionBackend: ref.watch(driverSessionBackendProviderAlias),
    networkInfo: ref.watch(networkInfoProvider),
    localCache: ref.watch(coDriverLocalCacheProvider),
    offlineQueue: ref.watch(offlineQueueProvider),
  );
});

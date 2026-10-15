import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../sync/data/providers/sync_providers.dart';
import '../../domain/repositories/inspection_repository.dart';
import '../datasources/inspection_local_cache.dart';
import '../repositories/inspection_repository_impl.dart';

final inspectionLocalCacheProvider = Provider<InspectionLocalCache>((ref) {
  return PrefsInspectionLocalCache(ref.watch(localStorageProvider));
});

/// طبقة البيانات تركّب مستودعها (المرحلة 3b) — الشبكة جزء من التركيب.
final inspectionRepositoryProvider = Provider<InspectionRepository>((ref) {
  return InspectionRepositoryImpl(
    ref.watch(inspectionBackendProvider),
    ref.watch(networkInfoProvider),
    ref.watch(syncEngineProvider),
    ref.watch(inspectionLocalCacheProvider),
  );
});

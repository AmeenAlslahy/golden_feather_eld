import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/contracts/vehicle_backend.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../datasources/vehicle_local_cache.dart';
import '../repositories/vehicle_repository_impl.dart';

// --- DI: طبقة البيانات هي من تركّب مستودعها (المرحلة 3b) ---

final vehicleBackendProviderAlias = Provider<VehicleBackend>((ref) {
  return ref.watch(vehicleBackendProvider);
});

/// كاش المركبات — يُمسح عند تبديل هوية السائق (انظر lib/app.dart).
final vehicleLocalCacheProvider = Provider<VehicleLocalCache>((ref) {
  return PrefsVehicleLocalCache(ref.watch(localStorageProvider));
});

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final vehicleBackend = ref.watch(vehicleBackendProviderAlias);
  final hardwareBackend = ref.watch(hardwareBackendProvider);
  final networkInfo = ref.watch(networkInfoProvider);

  return VehicleRepositoryImpl(
    vehicleBackend: vehicleBackend,
    hardwareBackend: hardwareBackend,
    networkInfo: networkInfo,
    // حتى تبقى قائمة المركبات متاحة بعد إعادة التشغيل بدون شبكة.
    cache: ref.watch(vehicleLocalCacheProvider),
  );
});

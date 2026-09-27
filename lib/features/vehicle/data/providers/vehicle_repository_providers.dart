import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/contracts/vehicle_backend.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/network/core_providers.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../repositories/vehicle_repository_impl.dart';

// --- DI: طبقة البيانات هي من تركّب مستودعها (المرحلة 3b) ---

final vehicleBackendProviderAlias = Provider<VehicleBackend>((ref) {
  return ref.watch(vehicleBackendProvider);
});

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final vehicleBackend = ref.watch(vehicleBackendProviderAlias);
  final networkInfo = ref.watch(networkInfoProvider);

  return VehicleRepositoryImpl(
    vehicleBackend: vehicleBackend,
    networkInfo: networkInfo,
  );
});

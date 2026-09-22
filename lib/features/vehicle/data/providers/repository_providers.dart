import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../repositories/vehicle_repository_impl.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepositoryImpl(
    vehicleBackend: ref.watch(vehicleBackendProvider),
    localDataSource: ref.watch(localStorageProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

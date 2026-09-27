import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/contracts/driver_session_backend.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/network/core_providers.dart';
import '../../domain/repositories/codriver_repository.dart';
import '../repositories/codriver_repository_impl.dart';

// --- DI: طبقة البيانات هي من تركّب مستودعها (المرحلة 3b) ---

final driverSessionBackendProviderAlias = Provider<DriverSessionBackend>((ref) {
  return ref.watch(driverSessionBackendProvider);
});

final coDriverRepositoryProvider = Provider<CoDriverRepository>((ref) {
  return CoDriverRepositoryImpl(
    driverSessionBackend: ref.watch(driverSessionBackendProviderAlias),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/contracts/inspection_backend.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/network/core_providers.dart';
import '../../domain/repositories/inspection_repository.dart';
import '../repositories/inspection_repository_impl.dart';

final inspectionBackendProviderAlias = Provider<InspectionBackend>((ref) {
  return ref.watch(inspectionBackendProvider);
});

final inspectionRepositoryProvider = Provider<InspectionRepository>((ref) {
  return InspectionRepositoryImpl(
    inspectionBackend: ref.watch(inspectionBackendProviderAlias),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

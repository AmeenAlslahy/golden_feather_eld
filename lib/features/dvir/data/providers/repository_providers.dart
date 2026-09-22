import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/contracts/dvir_backend.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/network/core_providers.dart';
import '../../domain/repositories/dvir_repository.dart';
import '../repositories/dvir_repository_impl.dart';

final dvirBackendProviderAlias = Provider<DvirBackend>((ref) {
  return ref.watch(dvirBackendProvider);
});

final dvirRepositoryProvider = Provider<DvirRepository>((ref) {
  return DvirRepositoryImpl(
    dvirBackend: ref.watch(dvirBackendProviderAlias),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

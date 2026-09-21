import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/providers/backend_providers.dart';
import '../../core/network/core_providers.dart';
import '../../core/services/local_storage_service.dart';

import '../../features/account/domain/repositories/account_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

// Import data implementations (ONLY ALLOWED IN THIS FILE)
import '../../features/account/data/repositories/account_repository_impl.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';

/// Composition Root for all Domain Repositories.
/// 
/// This is the ONLY file allowed to import `*impl.dart` files from the `data`
/// layers. The Presentation layer must only import the Domain interfaces and 
/// watch these providers.

// ==========================================================================
// Account Feature
// ==========================================================================

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepositoryImpl(
    accountBackend: ref.watch(accountBackendProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

// ==========================================================================
// Auth Feature
// ==========================================================================


final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl();
});

final traccarAuthRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    authBackend: ref.watch(authBackendProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
    configProvider: ref.watch(localStorageProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

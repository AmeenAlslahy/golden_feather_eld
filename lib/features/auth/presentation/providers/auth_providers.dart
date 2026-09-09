import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/auth_session_store.dart';
import '../../data/datasources/user_store.dart';

import '../../data/repositories/auth_repository_impl.dart';


final traccarAuthRemoteDataSourceProvider =
    Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final endpoints = ref.watch(endpointsProvider);
  return AuthRemoteDataSourceImpl(apiClient, endpoints);
});

final authSessionStoreProvider = Provider<AuthSessionStore>((ref) {
  return AuthSessionStoreImpl();
});

final userStoreProvider = Provider<UserStore>((ref) {
  return UserStoreImpl();
});

final traccarAuthRepositoryProvider = Provider<AuthRepository>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  final remoteDataSource = ref.watch(traccarAuthRemoteDataSourceProvider);
  final sessionStore = ref.watch(authSessionStoreProvider);
  final userStore = ref.watch(userStoreProvider);
  final networkInfo = ref.watch(networkInfoProvider);

  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    sessionStore: sessionStore,
    userStore: userStore,
    configProvider: localStorage,
    networkInfo: networkInfo,
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/auth_session_store.dart';
import '../../data/datasources/user_store.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../../core/config/app_environment.dart';

final traccarAuthRemoteDataSourceProvider =
    Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(rawDioProvider);
  final endpoints = ref.watch(endpointsProvider);
  return AuthRemoteDataSourceImpl(dio, endpoints);
});

final authSessionStoreProvider = Provider<AuthSessionStore>((ref) {
  return AuthSessionStoreImpl();
});

final userStoreProvider = Provider<UserStore>((ref) {
  return UserStoreImpl();
});

final traccarAuthRepositoryProvider = Provider<AuthRepository>((ref) {
  final localStorage = ref.watch(localStorageProvider);

  switch (AppEnvironmentConfig.current) {
    case AppEnvironment.mock:
    case AppEnvironment.staging:
      return MockAuthRepository(

        allowMockSuccess: true,
      );

    case AppEnvironment.development:
    case AppEnvironment.production:
    case AppEnvironment.temporaryTraccar:
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
  }
});

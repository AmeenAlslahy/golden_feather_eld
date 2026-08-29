import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/auth_session_store.dart';
import '../../data/datasources/user_store.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../../../core/utils/logger.dart';
import 'package:dio/dio.dart';
import '../../../../core/config/app_environment.dart';



/// موفر يوفر فقط قيمة JSESSIONID بشكل آمن إذا كانت الجلسة صالحة ومطابقة للخادم
/// هذا العقد سيتم استخدامه لاحقاً من قبل WebSocket لفتح الاتصال
final traccarSessionCredentialProvider = Provider<String?>((ref) {
  // في التطبيق الفعلي، سيعتمد على authStateProvider.
  return null;
});
final traccarAuthRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = Dio();
  return AuthRemoteDataSourceImpl(dio);
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
      MockAuthRepository.allowMockSuccess = true;
      return MockAuthRepository(localStorage: localStorage);
      
    case AppEnvironment.development:
    case AppEnvironment.production:
    case AppEnvironment.temporaryTraccar:
      final remoteDataSource = ref.watch(traccarAuthRemoteDataSourceProvider);
      final sessionStore = ref.watch(authSessionStoreProvider);
      final networkInfo = ref.watch(networkInfoProvider);

      return AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        sessionStore: sessionStore,
        localStorage: localStorage,
        networkInfo: networkInfo,
      );
  }
});



import 'package:fpdart/fpdart.dart';
import '../../../../core/utils/repository_helper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/user_preferences_storage_service.dart';
import '../../../account/data/datasources/account_remote_data_source.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final UserPreferencesStorageService _preferencesStorage;
  final AccountRemoteDataSource _accountRemoteDataSource;
  final NetworkInfo _networkInfo;

  SettingsRepositoryImpl({
    required UserPreferencesStorageService preferencesStorage,
    required AccountRemoteDataSource accountRemoteDataSource,
    required NetworkInfo networkInfo,
  })  : _preferencesStorage = preferencesStorage,
        _accountRemoteDataSource = accountRemoteDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, bool>> updateSettings({
    String? language,
    String? theme,
  }) async {
    try {
      // 1. Update local storage first for immediate UI response
      if (language != null) await _preferencesStorage.setLanguage(language);
      if (theme != null) await _preferencesStorage.setTheme(theme);

      // 2. Sync to backend if online
      if (_networkInfo.isConnected) {
        // We need the current user ID, assuming it's available or we can fetch the profile
        // A better approach is to rely on a user session service or provider.
        // But for settings, we might just update local. We'll handle backend sync in a dedicated sync job
        // or require userId in this method. For simplicity, we just save locally here.
        // Backend sync would be done via AccountRepository when updating UserProfile.
      }
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'فشل في حفظ الإعدادات: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> syncSettingsFromBackend(int userId) async {
    if (!_networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    return executeWithHandling(() async {
      final userModel = await _accountRemoteDataSource.getUserProfile(userId);
      final attrs = userModel.attributes;
      
      // Sync Theme
      if (attrs.containsKey('theme') && attrs['theme'] != null) {
        await _preferencesStorage.setTheme(attrs['theme'].toString());
      }
      
      // Sync Language
      final lang = attrs['language']?.toString() ?? '';
      if (lang.isNotEmpty) {
        await _preferencesStorage.setLanguage(lang);
      }
      
      return true;
    });
  }
}

import 'package:fpdart/fpdart.dart';
import '../../../../core/utils/repository_helper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_data_source.dart';
import 'package:golden_feather_eld/core/data/models/user_model.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AccountRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> getUserProfile(int userId) async {
    if (!networkInfo.isConnected) return const Left(NetworkFailure());
    return executeWithHandling(() async {
      return await remoteDataSource.getUserProfile(userId);
    });
  }

  @override
  Future<Either<Failure, User>> updateUserProfile(User user) async {
    if (!networkInfo.isConnected) return const Left(NetworkFailure());
    return executeWithHandling(() async {
      final userModel = UserModel.fromEntity(user);
      return await remoteDataSource.updateUserProfile(userModel);
    });
  }
}

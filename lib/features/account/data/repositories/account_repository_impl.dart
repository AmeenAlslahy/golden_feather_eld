import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_data_source.dart';
import '../models/user_model.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AccountRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserEntity>> getUserProfile(int userId) async {
    if (networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.getUserProfile(userId);
        return Right(userModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server Error', arabicMessage: e.arabicMessage));
      } catch (e) {
        return const Left(ServerFailure(message: 'Unexpected error occurred'));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateUserProfile(UserEntity user) async {
    if (networkInfo.isConnected) {
      try {
        final userModel = UserModel.fromEntity(user);
        final updatedModel = await remoteDataSource.updateUserProfile(userModel);
        return Right(updatedModel);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server Error', arabicMessage: e.arabicMessage));
      } catch (e) {
        return const Left(ServerFailure(message: 'Unexpected error occurred'));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}

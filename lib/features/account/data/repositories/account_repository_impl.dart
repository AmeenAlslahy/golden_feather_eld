import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/data/models/user_model.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';

import '../../../../backend/contracts/account_backend.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountBackend accountBackend;
  final NetworkInfo networkInfo;

  AccountRepositoryImpl({
    required this.accountBackend,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> getUserProfile(int userId) async {
    if (!networkInfo.isConnected) return const Left(NetworkFailure());

    final result = await accountBackend.getProfile(DriverId(userId));

    return result.fold(
        (error) => Left(ServerFailure(
            message: error.code,
            statusCode: error.context?['statusCode'] as int?)), (rawJson) {
      try {
        return Right(UserModel.fromJson(rawJson));
      } catch (e) {
        return Left(ServerFailure(message: 'Invalid data format: $e'));
      }
    });
  }

  @override
  Future<Either<Failure, User>> updateUserProfile(User user) async {
    if (!networkInfo.isConnected) return const Left(NetworkFailure());

    final userModel = UserModel.fromEntity(user);
    final driverIdInt = int.tryParse(user.id) ?? 0;
    
    final result = await accountBackend.updateProfile(
      driverId: DriverId(driverIdInt),
      update: userModel.toJson(),
    );

    return result.fold(
        (error) => Left(ServerFailure(
            message: error.code,
            statusCode: error.context?['statusCode'] as int?)), (rawJson) {
      try {
        return Right(UserModel.fromJson(rawJson));
      } catch (e) {
        return Left(ServerFailure(message: 'Invalid data format: $e'));
      }
    });
  }
}

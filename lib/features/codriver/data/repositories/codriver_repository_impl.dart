import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/codriver.dart';
import '../../domain/repositories/codriver_repository.dart';
import '../datasources/codriver_remote_data_source.dart';

class CoDriverRepositoryImpl implements CoDriverRepository {
  final CoDriverRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  CoDriverRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<CoDriver>>> getAvailableDrivers() async {
    if (networkInfo.isConnected) {
      try {
        final rawDrivers = await remoteDataSource.getAvailableDrivers();
        
        final drivers = rawDrivers.map((json) => CoDriver(
          id: json['id']?.toString() ?? '',
          name: json['name'] ?? 'Unknown',
          licenseNumber: json['attributes']?['licenseNumber'],
        )).toList();

        return Right(drivers);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message ?? 'Server Error'));
      } catch (e) {
        return const Left(ServerFailure(message: 'Unexpected error occurred'));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}

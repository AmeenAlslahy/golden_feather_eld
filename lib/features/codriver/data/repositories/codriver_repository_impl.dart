import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/codriver.dart';
import '../../domain/repositories/codriver_repository.dart';
import '../../../../backend/contracts/driver_session_backend.dart';

class CoDriverRepositoryImpl implements CoDriverRepository {
  final DriverSessionBackend driverSessionBackend;
  final NetworkInfo networkInfo;

  CoDriverRepositoryImpl({
    required this.driverSessionBackend,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<CoDriver>>> getAvailableDrivers() async {
    if (networkInfo.isConnected) {
      try {
        final result = await driverSessionBackend.getAvailableDrivers();
        return result.fold(
          (error) => Left(ServerFailure(message: error.code)),
          (rawDrivers) {
            final drivers = rawDrivers
            .map((json) => CoDriver(
                  id: json['id']?.toString() ?? '',
                  name: json['name'] ?? 'Unknown',
                  licenseNumber: json['attributes']?['licenseNumber'],
                ))
            .toList();

            return Right(drivers);
          }
        );
      } catch (e) {
        return const Left(ServerFailure(message: 'Unexpected error occurred'));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}

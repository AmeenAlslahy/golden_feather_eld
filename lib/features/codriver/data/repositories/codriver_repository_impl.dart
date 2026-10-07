import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_guard.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/current_codriver.dart';
import '../../domain/entities/codriver.dart';
import '../../domain/repositories/codriver_repository.dart';
import '../../../../backend/contracts/contract_enums.dart';
import '../../../../backend/contracts/driver_session_backend.dart';
import '../../../../domain/shared/value_objects.dart';

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
        return await result.fold(
          (error) => Left(ServerFailure(message: error.code)),
          (rawDrivers) {
            final drivers = rawDrivers
                .map(
                  (json) => CoDriver(
                    id: json['id']?.toString() ?? '',
                    name: json['name'] ?? 'Unknown',
                    licenseNumber: json['attributes']?['licenseNumber'],
                  ),
                )
                .toList();

            return Right(drivers);
          },
        );
      } catch (e) {
        return const Left(ServerFailure(message: 'Unexpected error occurred'));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, CurrentCoDriverRead>> getCurrentCoDriver() async {
    return guardedNetwork(networkInfo, () async {
      try {
        final result = await driverSessionBackend.getCurrentCoDriver();
        return await result.fold(
          (error) => Left(ServerFailure(message: error.code)),
          (json) {
            final read = parseCurrentCoDriver(json);
            if (read == null) {
              return const Left(
                ServerFailure(message: 'co_driver_response_unreadable'),
              );
            }
            return Right(read);
          },
        );
      } catch (_) {
        return const Left(ServerFailure(message: 'Unexpected error occurred'));
      }
    });
  }

  @override
  Future<Either<Failure, bool>> switchPrimary({
    required int coDriverId,
    String? reason,
  }) async {
    return guardedNetwork(networkInfo, () async {
      if (coDriverId <= 0) {
        return const Left(
          ServerFailure(message: 'Select a co-driver before switching.'),
        );
      }
      // Attempt 1: legacy-switch without reason (OAS: legacy-switch only accepts coDriverId)
      final legacyResult = await driverSessionBackend.switchPrimaryDriver(
        action: DutyStatusAction.legacySwitch,
        coDriverId: DriverId(coDriverId),
      );
      if (legacyResult.isRight()) {
        return const Right(true);
      }

      // Attempt 2: switch-primary with reason (FMCSA role switch requiring reason)
      final primaryResult = await driverSessionBackend.switchPrimaryDriver(
        action: DutyStatusAction.switchPrimary,
        coDriverId: DriverId(coDriverId),
        reason: reason ?? 'تبادل القيادة أثناء الاستراحة',
      );
      return primaryResult.fold(
        (error) => Left(ServerFailure(message: error.code)),
        (_) => const Right(true),
      );
    });
  }
}

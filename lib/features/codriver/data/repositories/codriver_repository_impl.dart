import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
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

  @override
  Future<Either<Failure, CurrentCoDriverRead>> getCurrentCoDriver() async {
    if (!networkInfo.isConnected) return const Left(NetworkFailure());
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
  }

  @override
  Future<Either<Failure, bool>> switchPrimary({required int coDriverId}) async {
    if (!networkInfo.isConnected) return const Left(NetworkFailure());
    if (coDriverId <= 0) {
      return const Left(ServerFailure(message: 'Select a co-driver before switching.'));
    }
    final result = await driverSessionBackend.switchPrimaryDriver(
      action: DutyStatusAction.switchPrimary,
      coDriverId: DriverId(coDriverId),
    );
    return result.fold(
      (error) => Left(ServerFailure(message: error.code)),
      (_) => const Right(true),
    );
  }

  @override
  Future<Either<Failure, bool>> updateSessionCoDriver({
    required bool remove,
    int? coDriverId,
    String? uniqueId,
  }) async {
    if (!networkInfo.isConnected) return const Left(NetworkFailure());
    final action = remove ? CoDriverAction.remove : CoDriverAction.link;
    if (!remove) {
      final id = uniqueId?.trim() ?? '';
      if (id.isEmpty || id == 'unknown' || id == 'No Vehicle') {
        return const Left(ServerFailure(message: 'vehicle_identifier_missing'));
      }
      if (coDriverId == null || coDriverId <= 0) {
        return const Left(
          ServerFailure(message: 'Select a co-driver before linking.'),
        );
      }
    }
    final trimmed = uniqueId?.trim();
    final result = await driverSessionBackend.manageCoDriver(
      action: action,
      coDriverId: coDriverId == null ? null : DriverId(coDriverId),
      uniqueId: trimmed == null || trimmed.isEmpty ? null : trimmed,
    );
    return result.fold(
      (error) => Left(ServerFailure(message: error.code)),
      (_) => const Right(true),
    );
  }
}

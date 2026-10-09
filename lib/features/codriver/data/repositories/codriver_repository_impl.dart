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

  /// Cache for available drivers and current link to survive offline periods
  static List<CoDriver> _cachedDrivers = [];
  static CurrentCoDriverRead? _cachedCurrentCoDriver;

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
          (error) {
            if (_cachedDrivers.isNotEmpty) return Right(_cachedDrivers);
            return Left(ServerFailure(message: error.code));
          },
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

            _cachedDrivers = drivers;
            return Right(drivers);
          },
        );
      } catch (e) {
        if (_cachedDrivers.isNotEmpty) return Right(_cachedDrivers);
        return const Left(ServerFailure(message: 'Unexpected error occurred'));
      }
    } else {
      if (_cachedDrivers.isNotEmpty) {
        return Right(_cachedDrivers);
      }
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, CurrentCoDriverRead>> getCurrentCoDriver() async {
    return guardedNetwork(networkInfo, () async {
      try {
        final result = await driverSessionBackend.getCurrentCoDriver();
        return await result.fold(
          (error) {
            if (_cachedCurrentCoDriver != null) {
              return Right(_cachedCurrentCoDriver!);
            }
            return Left(ServerFailure(message: error.code));
          },
          (json) {
            final read = parseCurrentCoDriver(json);
            if (read == null) {
              if (_cachedCurrentCoDriver != null) {
                return Right(_cachedCurrentCoDriver!);
              }
              return const Left(
                ServerFailure(message: 'co_driver_response_unreadable'),
              );
            }
            _cachedCurrentCoDriver = read;
            return Right(read);
          },
        );
      } catch (_) {
        if (_cachedCurrentCoDriver != null) {
          return Right(_cachedCurrentCoDriver!);
        }
        return const Left(ServerFailure(message: 'Unexpected error occurred'));
      }
    }, offline: () async {
      if (_cachedCurrentCoDriver != null) {
        return Right(_cachedCurrentCoDriver!);
      }
      return const Left(NetworkFailure());
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
        _cachedCurrentCoDriver = CurrentCoDriverRead(
          coDriverId: coDriverId,
          teamDrivingActive: true,
        );
        return const Right(true);
      }

      // Attempt 2: switch-primary with reason (FMCSA role switch requiring reason)
      final primaryResult = await driverSessionBackend.switchPrimaryDriver(
        action: DutyStatusAction.switchPrimary,
        coDriverId: DriverId(coDriverId),
        reason: reason ?? 'Co-driver shift change',
      );
      return primaryResult.fold(
        (error) => Left(ServerFailure(message: error.code)),
        (_) {
          _cachedCurrentCoDriver = CurrentCoDriverRead(
            coDriverId: coDriverId,
            teamDrivingActive: true,
          );
          return const Right(true);
        },
      );
    });
  }
}

import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/exception.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../../../../backend/contracts/vehicle_backend.dart';
import '../models/vehicle_model.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleBackend _vehicleBackend;
  final LocalStorageService _localDataSource;
  final NetworkInfo _networkInfo;

  VehicleRepositoryImpl({
    required VehicleBackend vehicleBackend,
    required LocalStorageService localDataSource,
    required NetworkInfo networkInfo,
  })  : _vehicleBackend = vehicleBackend,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, List<Vehicle>>> getVehicles() async {
    if (!_networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await _vehicleBackend.getLegacyVehicles();
      return result.fold(
        (error) => Left(ServerFailure(message: 'فشل: ${error.code}')),
        (data) {
          final vehicles = data.map((json) => VehicleModel.fromJson(json as Map<String, dynamic>)).toList();
          return Right(vehicles.cast<Vehicle>().toList());
        }
      );
    } catch (e) {
      return Left(ServerFailure(message: 'فشل جلب قائمة الشاحنات: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> selectVehicle(String vehicleId) async {
    try {
      // In a real ELD system, selecting a vehicle might also ping the backend
      // But for now, saving it locally is sufficient as the app's state
      await _localDataSource.saveSelectedVehicleId(vehicleId);
      return const Right(true);
    } catch (e) {
      return const Left(CacheFailure(message: 'فشل في حفظ الشاحنة محلياً'));
    }
  }

  @override
  Future<Either<Failure, Vehicle?>> getSelectedVehicle() async {
    try {
      final savedId = _localDataSource.selectedVehicleId;
      if (savedId == null) {
        return const Right(null);
      }

      // If we have an ID, we should get the full list to return the matching vehicle
      final vehiclesResult = await getVehicles();
      final Either<Failure, Vehicle?> result = vehiclesResult.match(
        (failure) => const Right(
            null), // If we can't fetch, we can't get the full object. A better offline approach would cache the list.
        (vehicles) {
          try {
            final vehicle = vehicles.firstWhere((v) => v.id == savedId);
            return Right(vehicle);
          } catch (e) {
            // Vehicle no longer assigned or doesn't exist
            _localDataSource.clearSelectedVehicle();
            return const Right(null);
          }
        },
      );
      return result;
    } catch (e) {
      return const Left(CacheFailure(message: 'فشل في قراءة الشاحنة المحفوظة'));
    }
  }
}

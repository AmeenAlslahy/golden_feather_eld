import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../../domain/vehicle_selection.dart';
import '../../../../backend/contracts/raw_json.dart';
import '../../../../backend/contracts/vehicle_backend.dart';
import '../../../../core/result/result.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleBackend _vehicleBackend;
  final NetworkInfo _networkInfo;

  /// The repository only lists/reads vehicles. Operating a vehicle
  /// (`POST /eld/hardware/connect`) has exactly one owner: the connection
  /// screen (`ConnectionNotifier.connect`). No second `connectSession` path.
  VehicleRepositoryImpl({
    required VehicleBackend vehicleBackend,
    required NetworkInfo networkInfo,
  }) : _vehicleBackend = vehicleBackend,
       _networkInfo = networkInfo;

  @override
  Future<Either<Failure, List<Vehicle>>> getVehicles() {
    return _readList(_vehicleBackend.getMyVehicles());
  }

  @override
  Future<Either<Failure, List<Vehicle>>> getCompanyVehicles() {
    return _readList(_vehicleBackend.getCompanyFleet());
  }

  Future<Either<Failure, List<Vehicle>>> _readList(
    Future<Result<RawJson>> request,
  ) async {
    if (!_networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await request;
      return await result.fold(
        (error) => Left(ServerFailure(message: _message(error))),
        (data) {
          final vehicles = parseVehicleList(data);
          if (vehicles == null) {
            return const Left(
              ServerFailure(message: 'vehicle_list_unreadable'),
            );
          }
          return Right(vehicles);
        },
      );
    } catch (_) {
      return const Left(ServerFailure(message: 'vehicle_list_unreadable'));
    }
  }

  @override
  Future<Either<Failure, Vehicle?>> getSelectedVehicle() async {
    final listed = await getVehicles();
    return listed.fold((failure) => Left(failure), (vehicles) {
      for (final vehicle in vehicles) {
        if (vehicle.activeForCurrentDriver == true ||
            vehicle.selectedByServer == true) {
          return Right(vehicle);
        }
      }
      return const Right(null);
    });
  }

  String _message(AppError error) {
    final status = error.context?['statusCode'];
    final statusCode = status is num ? status.toInt() : int.tryParse('$status');
    return vehicleOperateFailure(
      code: error.code,
      serverMessage: error.context?['serverMessage']?.toString(),
      statusCode: statusCode,
    );
  }
}

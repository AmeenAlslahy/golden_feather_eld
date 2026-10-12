import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../../domain/vehicle_selection.dart';
import '../../../../backend/contracts/hardware_backend.dart';
import '../../../../backend/contracts/raw_json.dart';
import '../../../../backend/contracts/vehicle_backend.dart';
import '../../../../core/result/result.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleBackend _vehicleBackend;
  final HardwareBackend _hardwareBackend;
  final NetworkInfo _networkInfo;

  VehicleRepositoryImpl({
    required VehicleBackend vehicleBackend,
    required HardwareBackend hardwareBackend,
    required NetworkInfo networkInfo,
  }) : _vehicleBackend = vehicleBackend,
       _hardwareBackend = hardwareBackend,
       _networkInfo = networkInfo;

  @override
  Future<Either<Failure, List<Vehicle>>> getVehicles() {
    return _readList(_vehicleBackend.getMyVehicles());
  }

  @override
  Future<Either<Failure, List<Vehicle>>> getCompanyVehicles() {
    return _readList(_vehicleBackend.getCompanyFleet());
  }

  List<Vehicle>? _cachedVehicles;

  Future<Either<Failure, List<Vehicle>>> _readList(
    Future<Result<RawJson>> request,
  ) async {
    if (!_networkInfo.isConnected) {
      return Right(_cachedVehicles ?? const []);
    }
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
          _cachedVehicles = vehicles;
          return Right(vehicles);
        },
      );
    } catch (_) {
      return const Left(ServerFailure(message: 'vehicle_list_unreadable'));
    }
  }

  @override
  Future<Either<Failure, bool>> selectVehicle(String uniqueId) async {
    final id = uniqueId.trim();
    if (id.isEmpty || id == 'unknown' || id == 'No Vehicle') {
      return const Left(ServerFailure(message: 'vehicle_identifier_missing'));
    }
    if (!_networkInfo.isConnected) {
      if (_cachedVehicles != null) {
        _cachedVehicles = _cachedVehicles!.map((v) {
          final match = v.uniqueId == id || v.id == id;
          return v.copyWith(
            activeForCurrentDriver: match,
            selectedByServer: match,
          );
        }).toList();
      }
      return const Right(true);
    }
    try {
      final result = await _hardwareBackend.connectSession(uniqueId: id);
      return await result.fold(
        (error) async => Left(ServerFailure(message: _message(error))),
        (_) async {
          if (_cachedVehicles != null) {
            _cachedVehicles = _cachedVehicles!.map((v) {
              final match = v.uniqueId == id || v.id == id;
              return v.copyWith(
                activeForCurrentDriver: match,
                selectedByServer: match,
              );
            }).toList();
          }
          return const Right(true);
        },
      );
    } catch (_) {
      return const Left(ServerFailure(message: 'rejected'));
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

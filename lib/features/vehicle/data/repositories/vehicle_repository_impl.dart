import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../../domain/vehicle_selection.dart';
import '../../../../backend/contracts/raw_json.dart';
import '../../../../backend/contracts/vehicle_backend.dart';
import '../../../../core/result/result.dart';
import '../datasources/vehicle_local_cache.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleBackend _vehicleBackend;
  final NetworkInfo _networkInfo;

  /// تخزين دائم لقائمة المركبات.
  ///
  /// قبله كانت القائمة في الذاكرة فقط، فكانت صفحة المركبة فارغة بعد
  /// أي إعادة تشغيل أثناء العمل بدون شبكة. نحفظ JSON الخام ونعيد
  /// تحليله بنفس المحلل المستخدم مع استجابة الخادم.
  final VehicleLocalCache? _cache;

  VehicleRepositoryImpl({
    required VehicleBackend vehicleBackend,
    required NetworkInfo networkInfo,
    VehicleLocalCache? cache,
  }) : _vehicleBackend = vehicleBackend,
       _networkInfo = networkInfo,
       _cache = cache {
    _restoreFromCache();
  }

  @override
  Future<Either<Failure, List<Vehicle>>> getVehicles() {
    return _readList(_vehicleBackend.getMyVehicles(), companyFleet: false);
  }

  @override
  Future<Either<Failure, List<Vehicle>>> getCompanyVehicles() {
    return _readList(_vehicleBackend.getCompanyFleet(), companyFleet: true);
  }

  List<Vehicle>? _cachedVehicles;
  List<Vehicle>? _cachedCompanyVehicles;

  void _restoreFromCache() {
    try {
      final personalRaw = _cache?.load();
      final companyRaw = _cache?.load(companyFleet: true);
      final personal = personalRaw == null
          ? null
          : parseVehicleList(personalRaw);
      final company = companyRaw == null ? null : parseVehicleList(companyRaw);
      if (personal != null) _cachedVehicles = personal;
      if (company != null) _cachedCompanyVehicles = company;
    } catch (e) {
      AppLogger.warning('Vehicle cache restore skipped: $e');
    }
  }

  Future<Either<Failure, List<Vehicle>>> _readList(
    Future<Result<RawJson>> request, {
    required bool companyFleet,
  }) async {
    final cached = companyFleet ? _cachedCompanyVehicles : _cachedVehicles;
    if (!_networkInfo.isConnected) {
      if (cached != null) {
        return Right(cached);
      }
      return const Left(NetworkFailure());
    }
    try {
      final result = await request;
      return await result.fold(
        (error) async {
          if (cached != null) {
            return Right(cached);
          }
          return Left(ServerFailure(message: _message(error)));
        },
        (data) async {
          final parsedVehicles = parseVehicleList(data);
          if (parsedVehicles == null) {
            if (cached != null) {
              return Right(cached);
            }
            return const Left(
              ServerFailure(message: 'vehicle_list_unreadable'),
            );
          }
          var vehicles = parsedVehicles;
          // `/my-vehicles` uses DriverVehicleClassification, whose current
          // contract omits Traccar's uniqueId. The company-fleet response
          // includes it, so enrich only by the shared server vehicle ID.
          // Never treat that numeric ID as the uniqueId itself.
          if (!companyFleet &&
              vehicles.any(
                (vehicle) => vehicle.uniqueId?.trim().isNotEmpty != true,
              )) {
            final fleetResult = await getCompanyVehicles();
            fleetResult.match((_) {}, (fleetVehicles) {
              final fleetById = {
                for (final vehicle in fleetVehicles)
                  if (vehicle.uniqueId?.trim().isNotEmpty == true)
                    vehicle.id: vehicle,
              };
              vehicles = vehicles
                  .map((vehicle) {
                    final fleetVehicle = fleetById[vehicle.id];
                    if (vehicle.uniqueId?.trim().isNotEmpty == true ||
                        fleetVehicle == null) {
                      return vehicle;
                    }
                    return vehicle.copyWith(
                      uniqueId: fleetVehicle.uniqueId,
                      deviceId: fleetVehicle.deviceId ?? vehicle.deviceId,
                    );
                  })
                  .toList(growable: false);
            });
          }
          if (companyFleet) {
            _cachedCompanyVehicles = vehicles;
          } else {
            _cachedVehicles = vehicles;
          }
          _cache?.save(data, companyFleet: companyFleet);
          return Right(vehicles);
        },
      );
    } catch (_) {
      if (cached != null) {
        return Right(cached);
      }
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

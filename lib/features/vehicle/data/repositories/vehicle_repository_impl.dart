import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../../domain/vehicle_selection.dart';
import '../../../../backend/contracts/hardware_backend.dart';
import '../../../../backend/contracts/raw_json.dart';
import '../../../../backend/contracts/vehicle_backend.dart';
import '../../../../core/result/result.dart';
import '../datasources/vehicle_local_cache.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleBackend _vehicleBackend;
  final HardwareBackend _hardwareBackend;
  final NetworkInfo _networkInfo;

  /// تخزين دائم لقائمة المركبات.
  ///
  /// قبله كانت القائمة في الذاكرة فقط، فكانت صفحة المركبة فارغة بعد
  /// أي إعادة تشغيل أثناء العمل بدون شبكة. نحفظ JSON الخام ونعيد
  /// تحليله بنفس المحلل المستخدم مع استجابة الخادم.
  final VehicleLocalCache? _cache;

  VehicleRepositoryImpl({
    required VehicleBackend vehicleBackend,
    required HardwareBackend hardwareBackend,
    required NetworkInfo networkInfo,
    VehicleLocalCache? cache,
  })  : _vehicleBackend = vehicleBackend,
       _hardwareBackend = hardwareBackend,
       _networkInfo = networkInfo,
       _cache = cache {
    _restoreFromCache();
  }

  @override
  Future<Either<Failure, List<Vehicle>>> getVehicles() {
    return _readList(_vehicleBackend.getMyVehicles());
  }

  @override
  Future<Either<Failure, List<Vehicle>>> getCompanyVehicles() {
    return _readList(_vehicleBackend.getCompanyFleet());
  }

  List<Vehicle>? _cachedVehicles;

  void _restoreFromCache() {
    try {
      final decoded = _cache?.load();
      if (decoded == null) return;
      final vehicles = parseVehicleList(decoded);
      if (vehicles != null && vehicles.isNotEmpty) _cachedVehicles = vehicles;
    } catch (e) {
      AppLogger.warning('Vehicle cache restore skipped: $e');
    }
  }

  void _persistToCache(RawJson raw) {
    _cache?.save(raw);
  }

  Future<Either<Failure, List<Vehicle>>> _readList(
    Future<Result<RawJson>> request,
  ) async {
    if (!_networkInfo.isConnected) {
      if (_cachedVehicles != null && _cachedVehicles!.isNotEmpty) {
        return Right(_cachedVehicles!);
      }
      return const Right([]);
    }
    try {
      final result = await request;
      return await result.fold(
        (error) {
          if (_cachedVehicles != null && _cachedVehicles!.isNotEmpty) {
            return Right(_cachedVehicles!);
          }
          return Left(ServerFailure(message: _message(error)));
        },
        (data) {
          final vehicles = parseVehicleList(data);
          if (vehicles == null) {
            if (_cachedVehicles != null && _cachedVehicles!.isNotEmpty) {
              return Right(_cachedVehicles!);
            }
            return const Left(
              ServerFailure(message: 'vehicle_list_unreadable'),
            );
          }
          _cachedVehicles = vehicles;
          _persistToCache(data);
          return Right(vehicles);
        },
      );
    } catch (_) {
      if (_cachedVehicles != null && _cachedVehicles!.isNotEmpty) {
        return Right(_cachedVehicles!);
      }
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
        (error) async {
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

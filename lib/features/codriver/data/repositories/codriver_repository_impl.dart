import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_guard.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/current_codriver.dart';
import '../../domain/entities/codriver.dart';
import '../../domain/repositories/codriver_repository.dart';
import '../../../../backend/contracts/contract_enums.dart';
import '../../../../backend/contracts/driver_session_backend.dart';
import '../../../../domain/shared/value_objects.dart';

import '../../../sync/domain/entities/pending_event.dart';
import '../../../sync/domain/repositories/offline_queue.dart';
import '../datasources/codriver_local_cache.dart';

class CoDriverRepositoryImpl implements CoDriverRepository {
  final DriverSessionBackend driverSessionBackend;
  final NetworkInfo networkInfo;
  final CoDriverLocalCache? localCache;
  final OfflineQueue? offlineQueue;

  /// P0 — المعرف الحالي للسائق (تُحقن من providers).
  ///
  /// بدونه كان حدث `switch_primary_driver` يخرج بلا مالك، فيُحجَر في
  /// الطابور للأبد (`quarantinedUnknownOwner`) ولا يصل خادم قط — رغم أن
  /// الواجهة تُبلغ السائق بالنجاح. ختم المالك هنا يجعله مقبولاً عند الإرسال.
  final int? Function()? readDriverId;

  /// Cache for available drivers and current link to survive offline periods
  static List<CoDriver> _cachedDrivers = [];
  static CurrentCoDriverRead? _cachedCurrentCoDriver;

  CoDriverRepositoryImpl({
    required this.driverSessionBackend,
    required this.networkInfo,
    this.localCache,
    this.offlineQueue,
    this.readDriverId,
  }) {
    if (localCache != null) {
      final cached = localCache!.loadAvailableDrivers();
      if (cached != null && cached.isNotEmpty) {
        _cachedDrivers = cached;
      }
      final current = localCache!.loadCurrentCoDriver();
      if (current != null) {
        _cachedCurrentCoDriver = current;
      }
    }
  }

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
            localCache?.saveAvailableDrivers(drivers);
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
      return const Right([]);
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
            localCache?.saveCurrentCoDriver(read);
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
      return const Right(CurrentCoDriverRead(
        coDriverId: null,
        teamDrivingActive: false,
      ));
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
        final current = CurrentCoDriverRead(
          coDriverId: coDriverId,
          teamDrivingActive: true,
        );
        _cachedCurrentCoDriver = current;
        await localCache?.saveCurrentCoDriver(current);
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
          final current = CurrentCoDriverRead(
            coDriverId: coDriverId,
            teamDrivingActive: true,
          );
          _cachedCurrentCoDriver = current;
          localCache?.saveCurrentCoDriver(current);
          return const Right(true);
        },
      );
    }, offline: () async {
      if (coDriverId <= 0) {
        return const Left(
          ServerFailure(message: 'Select a co-driver before switching.'),
        );
      }
      final current = CurrentCoDriverRead(
        coDriverId: coDriverId,
        teamDrivingActive: true,
      );
      _cachedCurrentCoDriver = current;
      await localCache?.saveCurrentCoDriver(current);
      if (offlineQueue != null) {
        final owner = readDriverId?.call();
        await offlineQueue!.enqueue(PendingEvent(
          // UUID بدل الطابع الزمني بالمللي: `switch_${ms}` كان يصطدم
          // عند تبديلين في نفس المللي ثانية، والطابور يستبدل بالمعرف.
          id: 'switch_${const Uuid().v4()}',
          type: 'switch_primary_driver',
          payload: {
            'coDriverId': coDriverId,
            'reason': reason ?? 'Co-driver shift change',
            // 🔴 ختم المالك — بدونه يُحجَر الحدث نهائياً عند الإرسال.
            if (owner != null && owner > 0) 'ownerDriverId': owner,
          },
          createdAt: DateTime.now().toUtc(),
        ));
      }
      return const Right(true);
    });
  }
}

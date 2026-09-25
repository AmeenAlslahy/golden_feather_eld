import 'package:fpdart/fpdart.dart';
import '../../../../backend/contracts/status_dashboard_backend.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../domain/duty_status/duty_status_code.dart';
import '../../../../domain/duty_status/status_dashboard.dart';
import '../../../../domain/duty_status/weekly_recap.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../domain/repositories/status_dashboard_repository.dart';

class StatusDashboardRepositoryImpl implements StatusDashboardRepository {
  final StatusDashboardBackend _backend;
  final NetworkInfo _networkInfo;

  StatusDashboardRepositoryImpl(this._backend, this._networkInfo);

  @override
  Future<Either<Failure, StatusDashboard>> getDashboard({DriverId? driverId}) async {
    if (!_networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    final result = await _backend.getDashboard(driverId: driverId);
    return result.fold(
      (error) => Left(ServerFailure(
          message: error.code,
          statusCode: error.context?['statusCode'] as int?)),
      (data) => Right(data),
    );
  }

  @override
  Future<Either<Failure, StatusDashboard>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
  }) async {
    if (!_networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    final result = await _backend.updateDutyStatus(
      status: status,
      notes: notes,
    );
    return result.fold(
      (error) => Left(ServerFailure(
          message: error.code,
          statusCode: error.context?['statusCode'] as int?)),
      (data) => Right(data),
    );
  }

  @override
  Future<Either<Failure, WeeklyRecap>> getWeeklyRecap({DriverId? driverId}) async {
    if (!_networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    final result = await _backend.getWeeklyRecap(driverId: driverId);
    return result.fold(
      (error) => Left(ServerFailure(
          message: error.code,
          statusCode: error.context?['statusCode'] as int?)),
      (data) => Right(data),
    );
  }
}

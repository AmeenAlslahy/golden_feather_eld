import 'package:fpdart/fpdart.dart';

import '../../../../backend/contracts/duty_status_backend.dart';
import '../../../../core/error/failure.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../domain/entities/pending_event.dart';
import '../../domain/usecases/sync_engine.dart';

class TraccarRemoteEventDispatcher implements RemoteEventDispatcher {
  final DutyStatusBackend _dutyStatusBackend;
  final AuthLocalDataSource _localDataSource;

  TraccarRemoteEventDispatcher(
      this._dutyStatusBackend, this._localDataSource);

  @override
  Future<Either<Failure, bool>> dispatch(PendingEvent event) async {
    try {
      if (event.type == 'duty_status') {
        final session = await _localDataSource.getSession();
        final driverId = session == null ? 0 : (int.tryParse(session.user.id) ?? 0);
        if (driverId <= 0) {
          return const Left(ServerFailure(message: 'Driver session is missing'));
        }
        final payload = Map<String, dynamic>.from(event.payload);
        payload['driverId'] = driverId;
        final result = await _dutyStatusBackend.submitLegacyDutyStatusEvent(driverId, payload);
        return result.fold(
          (error) => Left(ServerFailure(message: error.code)),
          (_) => const Right(true),
        );
      } else {
        // Fallback for generic Traccar events
        final result = await _dutyStatusBackend.submitLegacyGenericEvent(event.payload);
        return result.fold(
          (error) => Left(ServerFailure(message: error.code)),
          (_) => const Right(true),
        );
      }
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to dispatch event: $e',
      ));
    }
  }
}

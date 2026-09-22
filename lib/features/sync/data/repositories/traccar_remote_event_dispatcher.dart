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
        int driverId = 0;
        if (event.payload.containsKey('driverId')) {
          driverId = event.payload['driverId'] as int;
        } else if (session != null) {
          driverId = int.tryParse(session.user.id) ?? 0;
        }
        final result = await _dutyStatusBackend.submitLegacyDutyStatusEvent(driverId, event.payload);
        return await Future.value(result.fold(
          (error) => Left(ServerFailure(message: error.code)),
          (_) => const Right(true),
        ));
      } else {
        // Fallback for generic Traccar events
        final result = await _dutyStatusBackend.submitLegacyGenericEvent(event.payload);
        return await Future.value(result.fold(
          (error) => Left(ServerFailure(message: error.code)),
          (_) => const Right(true),
        ));
      }
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to dispatch event: $e',
      ));
    }
  }
}

import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/pending_event.dart';
import '../../domain/usecases/sync_engine.dart';
import '../../../../backend/contracts/duty_status_backend.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';

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
        if (session != null) {
          driverId = int.tryParse(session.user.id) ?? 0;
        }
        final result = await _dutyStatusBackend.submitLegacyDutyStatusEvent(driverId, event.payload);
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

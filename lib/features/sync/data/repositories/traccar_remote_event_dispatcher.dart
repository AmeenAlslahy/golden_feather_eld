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
        final driverId = session == null ? 0 : (int.tryParse(session.user.id) ?? 0);
        if (driverId <= 0) {
          return const Left(ServerFailure(message: 'Driver session is missing'));
        }
        final payload = Map<String, dynamic>.from(event.payload);
        payload['driverId'] = driverId;

        // Fix for old queued events in SQLite that have snake_case statuses
        if (payload['status'] is String) {
          final s = payload['status'] as String;
          switch (s) {
            case 'driving': payload['status'] = 'DRIVING'; break;
            case 'on_duty': payload['status'] = 'ON_DUTY'; break;
            case 'off_duty': payload['status'] = 'OFF_DUTY'; break;
            case 'sleeper':
            case 'sleeper_berth': payload['status'] = 'SLEEPER'; break;
            case 'yard_move': payload['status'] = 'YARD_MOVE'; break;
            case 'personal_use':
            case 'personal_conveyance': payload['status'] = 'PERSONAL_CONVEYANCE'; break;
          }
        }

        final result = await _dutyStatusBackend.submitLegacyDutyStatusEvent(driverId, payload);
        return await result.fold(
          (error) => Left(ServerFailure(message: error.code)),
          (_) => const Right(true),
        );
      } else {
        // Fallback for generic Traccar events
        final result = await _dutyStatusBackend.submitLegacyGenericEvent(event.payload);
        return await result.fold(
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

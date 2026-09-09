import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/pending_event.dart';
import '../../domain/usecases/sync_engine.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/data/datasources/auth_session_store.dart';

class TraccarRemoteEventDispatcher implements RemoteEventDispatcher {
  final ApiClient _apiClient;
  final ApiEndpoints _endpoints;
  final AuthSessionStore _authSessionStore;

  TraccarRemoteEventDispatcher(
      this._apiClient, this._endpoints, this._authSessionStore);

  @override
  Future<Either<Failure, bool>> dispatch(PendingEvent event) async {
    try {
      if (event.type == 'duty_status') {
        final session = await _authSessionStore.getSession();
        int driverId = 0;
        if (session != null) {
          driverId = int.tryParse(session.user.id) ?? 0;
        }
        await _apiClient.post(
          _endpoints.driverDutyStatus(driverId),
          data: event.payload,
        );
      } else {
        // Fallback for generic Traccar events
        await _apiClient.post(
          _endpoints.events,
          data: event.payload,
        );
      }
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to dispatch event: $e',
      ));
    }
  }
}

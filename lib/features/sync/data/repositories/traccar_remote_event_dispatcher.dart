import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/pending_event.dart';
import '../../domain/usecases/sync_engine.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class TraccarRemoteEventDispatcher implements RemoteEventDispatcher {
  final ApiClient _apiClient;
  final ApiEndpoints _endpoints;

  TraccarRemoteEventDispatcher(this._apiClient, this._endpoints);

  @override
  Future<Either<Failure, bool>> dispatch(PendingEvent event) async {
    try {
      if (event.type == 'duty_status') {
        final driverId = int.tryParse(event.payload['driverId']?.toString() ?? '0') ?? 0;
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
        arabicMessage: 'فشل إرسال الحدث إلى خادم التتبع',
      ));
    }
  }
}

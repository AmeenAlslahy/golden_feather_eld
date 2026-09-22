import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';
import 'package:golden_feather_eld/features/sync/domain/usecases/sync_engine.dart';

class FailClosedRemoteEventDispatcher implements RemoteEventDispatcher {
  @override
  Future<Either<Failure, bool>> dispatch(PendingEvent event) async {
    // Fail immediately, mimicking no network.
    return const Left(ServerFailure(message: 'Network is unreachable (Test Mock)'));
  }
}

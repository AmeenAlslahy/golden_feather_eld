import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/pending_event.dart';
import '../../domain/usecases/sync_engine.dart';
import '../../../../core/network/api_client.dart';

class TraccarRemoteEventDispatcher implements RemoteEventDispatcher {
  final ApiClient _apiClient;

  TraccarRemoteEventDispatcher(this._apiClient);

  @override
  Future<Either<Failure, bool>> dispatch(PendingEvent event) async {
    try {
      // إرسال الحدث عبر Traccar API
      // ملاحظة: قد تحتاج لتعديل المسار بناءً على مسار الإرسال الفعلي في Traccar (OsmAnd protocol أو HTTP API)
      await _apiClient.post(
        '/api/events', // قم بتحديث هذا المسار حسب المطلوب
        data: event.payload,
      );
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to dispatch event to Traccar: $e',
        arabicMessage: 'فشل إرسال الحدث إلى خادم التتبع',
      ));
    }
  }
}

import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../repositories/tracking_repository.dart';

/// حالة استخدام: إيقاف التتبع
class StopTracking {
  final TrackingRepository _repository;

  StopTracking(this._repository);

  Future<Either<Failure, bool>> call() async {
    return _repository.stopTracking();
  }
}

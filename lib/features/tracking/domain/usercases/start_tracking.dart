import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../repositories/tracking_repository.dart';

/// حالة استخدام: بدء التتبع
class StartTracking {
  final TrackingRepository _repository;

  StartTracking(this._repository);

  Future<Either<Failure, bool>> call() async {
    return _repository.startTracking();
  }
}

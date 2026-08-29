import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/location_entity.dart';
import '../repositories/tracking_repository.dart';

/// حالة استخدام: الحصول على الموقع الحالي
class GetCurrentLocation {
  final TrackingRepository _repository;

  GetCurrentLocation(this._repository);

  Future<Either<Failure, LocationEntity>> call() async {
    return _repository.getCurrentLocation();
  }
}

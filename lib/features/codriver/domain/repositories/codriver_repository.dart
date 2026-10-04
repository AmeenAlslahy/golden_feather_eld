import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../current_codriver.dart';
import '../entities/codriver.dart';

abstract class CoDriverRepository {
  Future<Either<Failure, List<CoDriver>>> getAvailableDrivers();

  Future<Either<Failure, CurrentCoDriverRead>> getCurrentCoDriver();

  Future<Either<Failure, bool>> switchPrimary({required int coDriverId});
}

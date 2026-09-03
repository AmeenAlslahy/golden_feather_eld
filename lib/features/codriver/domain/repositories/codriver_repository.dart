import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/codriver.dart';

abstract class CoDriverRepository {
  Future<Either<Failure, List<CoDriver>>> getAvailableDrivers();
}

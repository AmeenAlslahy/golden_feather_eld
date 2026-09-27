import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/vehicle.dart';

/// واجهة مستودع المركبات
abstract class VehicleRepository {
  /// جلب قائمة المركبات المتاحة للسائق
  Future<Either<Failure, List<Vehicle>>> getVehicles();

  /// عرض أسطول الشركة. الظهور ليس إذناً بالتشغيل.
  Future<Either<Failure, List<Vehicle>>> getCompanyVehicles();

  /// جلب المركبة المختارة حالياً
  Future<Either<Failure, Vehicle?>> getSelectedVehicle();
}

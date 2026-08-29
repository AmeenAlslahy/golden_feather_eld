import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/vehicle.dart';

/// واجهة مستودع المركبات
abstract class VehicleRepository {
  /// جلب قائمة المركبات المتاحة للسائق
  Future<Either<Failure, List<Vehicle>>> getVehicles();

  /// اختيار مركبة للجلسة الحالية
  Future<Either<Failure, bool>> selectVehicle(String vehicleId);

  /// جلب المركبة المختارة حالياً
  Future<Either<Failure, Vehicle?>> getSelectedVehicle();
}

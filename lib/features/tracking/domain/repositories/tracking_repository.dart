import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/location_entity.dart';

/// واجهة مستودع التتبع
abstract class TrackingRepository {
  /// بدء خدمة التتبع
  Future<Either<Failure, bool>> startTracking();

  /// إيقاف خدمة التتبع
  Future<Either<Failure, bool>> stopTracking();

  /// هل التتبع نشط
  Future<bool> isTracking();

  /// الحصول على الموقع الحالي
  Future<Either<Failure, LocationEntity>> getCurrentLocation();

  /// طلب تحديث فوري للموقع
  Future<Either<Failure, LocationEntity>> requestPosition({String? alarm});

  /// الحصول على سجلات التتبع
  Future<Either<Failure, List<TrackingLogEntity>>> getLogs();

  /// مسح السجلات
  Future<Either<Failure, bool>> clearLogs();

  /// تحديث إعدادات التتبع
  Future<Either<Failure, bool>> updateConfig(TrackingConfigEntity config);

  /// الحصول على الإعدادات الحالية
  Future<TrackingConfigEntity> getCurrentConfig();

  /// مجرى المواقع المباشر
  Stream<LocationEntity> get locationStream;
}

import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../tracking/data/services/tracking_service.dart';

/// حالة استخدام: تطبيق الإعدادات عن بعد
class ApplyRemoteConfig {
  final LocalStorageService _storage;
  final TrackingService _trackingService;

  ApplyRemoteConfig({
    required LocalStorageService storage,
    required TrackingService trackingService,
  })  : _storage = storage,
        _trackingService = trackingService;

  Future<Either<Failure, bool>> call(Uri uri) async {
    try {
      // التحقق من صحة الرابط
      if (uri.scheme.isEmpty) {
        return const Left(ValidationFailure(
          message: 'رابط غير صالح',
          arabicMessage: 'الرابط غير صالح',
        ));
      }

      // تطبيق الإعدادات من الرابط
      await _storage.applyFromUri(uri);

      // تحديث إعدادات المتتبع
      await _trackingService.updateConfig();

      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(
        message: 'فشل تطبيق الإعدادات: $e',
        arabicMessage: 'فشل تطبيق الإعدادات',
      ));
    }
  }
}




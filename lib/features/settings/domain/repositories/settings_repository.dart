import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';

abstract class SettingsRepository {
  /// تحديث تفضيلات التطبيق محلياً وعلى الباك اند
  Future<Either<Failure, bool>> updateSettings({
    String? language,
    String? theme,
  });

  /// مزامنة الإعدادات من الباك اند وتطبيقها محلياً
  Future<Either<Failure, bool>> syncSettingsFromBackend(int userId);
}

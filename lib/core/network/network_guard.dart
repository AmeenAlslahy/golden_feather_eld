import 'package:fpdart/fpdart.dart';

import '../error/failure.dart';
import 'network_info.dart';

/// حارس الشبكة الموحد.
///
/// كان النمط `if (!networkInfo.isConnected) return Left(NetworkFailure())`
/// منسوخاً في ستة مستودعات بفروق صغيرة — الآن مسار واحد:
///
/// ```dart
/// return guardedNetwork(_networkInfo, () async {
///   final result = await _backend.getDashboard(driverId: driverId);
///   ...
/// });
/// ```
///
/// المستودعات التي لها سلوك أوفلاين خاص (لقطة السجلات، جلسة المصادقة
/// المحلية، عدّاد المزامنة) تمرر [offline] بدل الرفض الافتراضي.
Future<Either<Failure, T>> guardedNetwork<T>(
  NetworkInfo networkInfo,
  Future<Either<Failure, T>> Function() action, {
  Future<Either<Failure, T>> Function()? offline,
}) {
  if (networkInfo.isConnected) return action();
  return offline != null
      ? offline()
      : Future.value(const Left(NetworkFailure()));
}

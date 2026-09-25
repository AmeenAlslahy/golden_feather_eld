import 'package:fpdart/fpdart.dart';

import '../error/exception.dart';
import '../error/failure.dart';
import '../network/network_info.dart';
import 'logger.dart';

final _defaultNetworkInfo = NetworkInfoImpl();

/// Helper function to standardize error handling across all repositories.
Future<Either<Failure, T>> executeWithHandling<T>(
  Future<T> Function() action, {
  String? tag,
  bool checkNetworkFirst = false,
  NetworkInfo? networkInfo,
}) async {
  if (checkNetworkFirst) {
    final checker = networkInfo ?? _defaultNetworkInfo;
    if (!(checker.isConnected)) {
      AppLogger.error(
          '${tag ?? 'Repository'} NetworkInfo: No Internet Connection');
      return const Left(NetworkFailure());
    }
  }

  try {
    final result = await action();
    return Right(result);
  } on ServerException catch (e) {
    AppLogger.error('${tag ?? 'Repository'} ServerException: ${e.message}');
    // 401 في جلسة قائمة = انتهاء صلاحية الجلسة، وليس كلمة مرور خاطئة —
    // InvalidCredentialsFailure كان يخبر المستخدم بأن أخطاءه في البيانات.
    if (e.statusCode == 401) {
      return const Left(AuthFailure());
    }
    return Left(ServerFailure(
      message: e.message ?? 'فشل الاتصال بالخادم',
      statusCode: e.statusCode,
    ));
  } on OfflineException catch (e) {
    AppLogger.error('${tag ?? 'Repository'} OfflineException: ${e.message}');
    return const Left(NetworkFailure());
  } on UnauthorizedException catch (e) {
    AppLogger.error(
        '${tag ?? 'Repository'} UnauthorizedException: ${e.message}');
    return Left(AuthFailure(
      message: e.message ?? 'انتهت صلاحية الجلسة',
    ));
  } on CacheException catch (e) {
    AppLogger.error('${tag ?? 'Repository'} CacheException: ${e.message}');
    return Left(CacheFailure(
      message: e.message ?? 'خطأ في التخزين المؤقت',
    ));
  } catch (e, stackTrace) {
    AppLogger.error(
        '${tag ?? 'Repository'} Unexpected Exception: $e', e, stackTrace);
    // التفاصيل تبقى في السجلات فقط — نص الاستثناء قد يحوي مسارات أو بيانات حساسة.
    return const Left(ServerFailure(
      message: 'An unexpected error occurred',
    ));
  }
}

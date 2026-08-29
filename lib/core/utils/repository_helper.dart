import 'package:fpdart/fpdart.dart';
import '../error/failure.dart';
import '../error/exception.dart';
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
    if (!(await checker.isConnected)) {
      AppLogger.error('${tag ?? 'Repository'} NetworkInfo: No Internet Connection');
      return const Left(NetworkFailure());
    }
  }

  try {
    final result = await action();
    return Right(result);
  } on ServerException catch (e) {
    AppLogger.error('${tag ?? 'Repository'} ServerException: ${e.message}');
    return Left(ServerFailure(
      message: e.message ?? 'فشل الاتصال بالخادم',
      arabicMessage: e.arabicMessage ?? 'فشل الاتصال بالخادم',
      statusCode: e.statusCode,
    ));
  } on OfflineException catch (e) {
    AppLogger.error('${tag ?? 'Repository'} OfflineException: ${e.message}');
    return const Left(NetworkFailure());
  } on UnauthorizedException catch (e) {
    AppLogger.error('${tag ?? 'Repository'} UnauthorizedException: ${e.message}');
    return Left(AuthFailure(
      message: e.message ?? 'انتهت صلاحية الجلسة',
      arabicMessage: e.arabicMessage ?? 'انتهت صلاحية الجلسة',
    ));
  } on CacheException catch (e) {
    AppLogger.error('${tag ?? 'Repository'} CacheException: ${e.message}');
    return Left(CacheFailure(
      message: e.message ?? 'خطأ في التخزين المؤقت',
    ));
  } catch (e, stackTrace) {
    AppLogger.error('${tag ?? 'Repository'} Unexpected Exception: $e', e, stackTrace);
    return Left(ServerFailure(
      message: 'An unexpected error occurred: $e',
      arabicMessage: 'حدث خطأ غير متوقع',
    ));
  }
}

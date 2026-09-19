import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';

abstract class AuthRepository {
  /// تسجيل الدخول إلى الخادم
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  /// التحقق من صلاحية الجلسة المحفوظة واستعادتها
  Future<Either<Failure, User>> checkAndRestoreSession();

  /// تسجيل الخروج وحذف الجلسة
  Future<Either<Failure, Unit>> logout();

  /// الحصول على الجلسة الحالية (بدون اتصال بالشبكة)
  Future<Either<Failure, User>> getCurrentSession();
}

import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import 'package:golden_feather_eld/features/account/domain/entities/user.dart';

abstract class AccountRepository {
  /// جلب بيانات المستخدم بناءً على المعرف
  Future<Either<Failure, User>> getUserProfile(int userId);

  /// تحديث بيانات المستخدم
  Future<Either<Failure, User>> updateUserProfile(User user);
}

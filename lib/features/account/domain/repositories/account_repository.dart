import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';

import '../../../../core/error/failure.dart';

abstract class AccountRepository {
  /// جلب بيانات المستخدم بناءً على المعرف
  Future<Either<Failure, User>> getUserProfile(int userId);

  /// تحديث بيانات المستخدم
  Future<Either<Failure, User>> updateUserProfile(User user);
}

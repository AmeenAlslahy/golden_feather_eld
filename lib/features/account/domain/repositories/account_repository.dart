import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/user_entity.dart';

abstract class AccountRepository {
  /// جلب بيانات المستخدم بناءً على المعرف
  Future<Either<Failure, UserEntity>> getUserProfile(int userId);

  /// تحديث بيانات المستخدم
  Future<Either<Failure, UserEntity>> updateUserProfile(UserEntity user);
}

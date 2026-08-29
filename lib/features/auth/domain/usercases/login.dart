import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';

import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// حالة استخدام: تسجيل الدخول
class Login {
  final AuthRepository _repository;

  Login(this._repository);

  Future<Either<Failure, AuthSession>> call({
    required String email,
    required String password,
    String? serverUrl,
  }) async {
    // التحقق من البيانات
    if (email.isEmpty) {
      return const Left(ValidationFailure(
        message: 'البريد الإلكتروني مطلوب',
        arabicMessage: 'البريد الإلكتروني مطلوب',
      ));
    }

    if (password.isEmpty) {
      return const Left(ValidationFailure(
        message: 'كلمة المرور مطلوبة',
        arabicMessage: 'كلمة المرور مطلوبة',
      ));
    }

    return _repository.login(email: email, password: password);
  }
}

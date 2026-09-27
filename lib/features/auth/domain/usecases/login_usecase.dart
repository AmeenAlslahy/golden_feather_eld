import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import '../repositories/auth_repository.dart';
import '../entities/value_objects/login_identifier.dart';
import '../entities/value_objects/password.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  /// تنفيذ عملية تسجيل الدخول
  Future<Either<Failure, User>> call({
    required LoginIdentifier identifier,
    required Password password,
  }) async {
    // التحقق من صحة المدخلات في طبقة Use Case قبل الوصول للـ Repository
    if (!identifier.isValid) {
      return const Left(ValidationFailure(
        message: 'Invalid identifier format',
      ));
    }

    if (!password.isValid) {
      return const Left(ValidationFailure(
        message: 'Invalid password',
      ));
    }

    // استدعاء المستودع
    return await repository.login(
      identifier: identifier.value,
      password: password.value,
    );
  }
}

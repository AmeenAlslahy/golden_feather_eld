import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import 'package:golden_feather_eld/core/entities/user.dart';
import '../repositories/auth_repository.dart';
import '../entities/value_objects/email.dart';
import '../entities/value_objects/password.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  /// تنفيذ عملية إنشاء الحساب
  Future<Either<Failure, User>> call({
    required String name,
    required Email email,
    required Password password,
  }) async {
    // التحقق من صحة المدخلات
    if (name.trim().isEmpty) {
      return Left(ValidationFailure(
        message: 'Name is required',
        ));
    }

    if (!email.isValid) {
      return Left(ValidationFailure(
        message: 'Invalid email format',
        ));
    }

    if (!password.isValid) {
      return Left(ValidationFailure(
        message: 'Invalid password',
        ));
    }

    // استدعاء المستودع
    return await repository.register(
      name: name.trim(),
      email: email.value,
      password: password.value,
    );
  }
}

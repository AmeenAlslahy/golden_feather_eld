import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../repositories/auth_repository.dart';

/// حالة استخدام: تسجيل الخروج
class Logout {
  final AuthRepository _repository;

  Logout(this._repository);

  Future<Either<Failure, Unit>> call() async {
    return _repository.logout();
  }
}

/// مزود حالة استخدام تسجيل الخروج

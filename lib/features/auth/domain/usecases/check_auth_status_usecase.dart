import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import 'package:golden_feather_eld/features/account/domain/entities/user.dart';
import '../repositories/auth_repository.dart';

class CheckAuthStatusUseCase {
  final AuthRepository repository;

  CheckAuthStatusUseCase(this.repository);

  /// التحقق من حالة المصادقة واستعادة الجلسة
  Future<Either<Failure, User>> call() async {
    return await repository.checkAndRestoreSession();
  }
}

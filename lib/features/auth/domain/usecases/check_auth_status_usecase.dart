import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';

import '../../../../core/error/failure.dart';
import '../repositories/auth_repository.dart';

class CheckAuthStatusUseCase {
  final AuthRepository repository;

  CheckAuthStatusUseCase(this.repository);

  /// التحقق من حالة المصادقة واستعادة الجلسة
  Future<Either<Failure, User>> call() async {
    return await repository.checkAndRestoreSession();
  }
}

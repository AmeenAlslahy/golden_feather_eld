import '../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  /// تنفيذ عملية تسجيل الخروج ومسح الجلسة
  Future<void> call() async {
    await repository.logout();
  }
}

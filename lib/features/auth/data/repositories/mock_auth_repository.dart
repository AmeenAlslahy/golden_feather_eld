import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import 'package:golden_feather_eld/core/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';


class MockAuthRepository implements AuthRepository {
  final bool allowMockSuccess;
  bool _hasSession = false;

  MockAuthRepository({
    this.allowMockSuccess = true,
  });

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    if (!allowMockSuccess) {
      return const Left(AuthFailure(message: 'Mock login disabled by flag'));
    }

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network

    if (email == 'admin@demo.com' && password == 'admin123') {
      _hasSession = true;
      final user = User(
        id: '1',
        fullName: 'Ameen Alsalahi',
        email: 'admin@demo.com',
        username: 'admin@demo.com',
        role: UserRole.admin,
        createdAt: DateTime.now(),
      );

      return Right(user);
    }

    return const Left(AuthFailure(
      message: 'Invalid credentials',
      ));
  }

  @override
  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!allowMockSuccess) {
      return const Left(ServerFailure(message: 'Mock registration failed'));
    }

    await Future.delayed(const Duration(milliseconds: 500));
    return login(email: 'admin@demo.com', password: 'admin123'); // Fake login
  }

  @override
  Future<Either<Failure, User>> checkAndRestoreSession() async {
    if (allowMockSuccess && _hasSession) {
      final user = User(
        id: '1',
        fullName: 'Ameen Alsalahi',
        email: 'admin@demo.com',
        username: 'admin@demo.com',
        role: UserRole.admin,
        createdAt: DateTime.now(),
      );
      return Right(user);
    }
    return const Left(SessionMissingFailure());
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    _hasSession = false;
    await Future.delayed(const Duration(milliseconds: 100));
    return const Right(unit);
  }

  @override
  Future<Either<Failure, User>> getCurrentSession() async {
    if (_hasSession) {
      return Right(User(
        id: '1',
        fullName: 'Mock User',
        email: 'mock@demo.com',
        username: 'mock@demo.com',
        role: UserRole.fieldWorker,
        createdAt: DateTime.now(),
      ));
    }
    return const Left(SessionMissingFailure());
  }
}

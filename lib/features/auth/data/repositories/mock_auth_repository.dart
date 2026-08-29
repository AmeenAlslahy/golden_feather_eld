import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/services/local_storage_service.dart';

class MockAuthRepository implements AuthRepository {
  final LocalStorageService _localStorage;

  static bool allowMockSuccess = false;
  bool _hasSession = false;

  MockAuthRepository({required LocalStorageService localStorage})
      : _localStorage = localStorage;

  @override
  Future<Either<Failure, AuthSession>> login({
    required String email,
    required String password,
  }) async {
    if (!allowMockSuccess) {
      return const Left(AuthFailure(message: 'Mock login disabled by flag'));
    }

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network

    if (email == 'admin@demo.com' && password == 'admin123') {
      _hasSession = true;
      final session = AuthSession(
        sessionCredential: 'mock_session_cookie',
        userMetadata: const {
          'id': 1,
          'name': 'Ameen Alsalahi',
          'email': 'admin@demo.com',
          'administrator': true,
        },
        serverOrigin: 'mock_origin',
        createdAt: DateTime.now(),
      );

      return Right(session);
    }

    return const Left(AuthFailure(
      message: 'Invalid credentials',
      arabicMessage: 'بيانات الدخول غير صحيحة',
    ));
  }

  @override
  Future<Either<Failure, AuthSession>> register({
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
  Future<Either<Failure, AuthSession>> checkAndRestoreSession() async {
    if (allowMockSuccess && _hasSession) {
      final session = AuthSession(
        sessionCredential: 'mock_session_cookie',
        userMetadata: const {
          'id': 1,
          'name': 'Ameen Alsalahi',
          'email': 'admin@demo.com',
          'administrator': true,
        },
        serverOrigin: 'mock_origin',
        createdAt: DateTime.now(),
      );
      return Right(session);
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
  Future<Either<Failure, AuthSession>> getCurrentSession() async {
    if (_hasSession) {
      return Right(AuthSession(
        sessionCredential: 'mock_session_cookie',
        userMetadata: const {},
        serverOrigin: 'mock_origin',
        createdAt: DateTime.now(),
      ));
    }
    return const Left(SessionMissingFailure());
  }
}

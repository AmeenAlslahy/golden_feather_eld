import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/error/exception.dart';
import 'package:golden_feather_eld/core/utils/repository_helper.dart';

void main() {
  group('executeWithHandling', () {
    test('wraps a successful action in Right', () async {
      final result = await executeWithHandling<int>(() async => 42);
      expect(result, isA<Right<Failure, int>>());
      expect((result as Right<Failure, int>).value, 42);
    });

    test('401 ServerException maps to AuthFailure, not InvalidCredentialsFailure',
        () async {
      // A 401 on an existing session means the session expired; telling the
      // driver the credentials are wrong sends them to re-login blindly.
      final result = await executeWithHandling<int>(
        () async => throw const ServerException(
          statusCode: 401,
          message: 'unauthorized',
        ),
      );
      expect(result, isA<Left<Failure, int>>());
      final failure = (result as Left<Failure, int>).value;
      expect(failure, isA<AuthFailure>());
      expect(failure, isNot(isA<InvalidCredentialsFailure>()));
    });

    test('500 ServerException maps to ServerFailure with the server message',
        () async {
      final result = await executeWithHandling<int>(
        () async => throw const ServerException(
          statusCode: 500,
          message: 'backend down',
        ),
      );
      final failure = (result as Left<Failure, int>).value;
      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'backend down');
      expect(failure.statusCode, 500);
    });

    test('OfflineException maps to NetworkFailure', () async {
      final result = await executeWithHandling<int>(
        () async => throw const OfflineException('timed out'),
      );
      final failure = (result as Left<Failure, int>).value;
      expect(failure, isA<NetworkFailure>());
    });

    test('UnauthorizedException maps to AuthFailure keeping its message',
        () async {
      final result = await executeWithHandling<int>(
        () async => throw const UnauthorizedException(
          message: 'انتهت صلاحية الجلسة',
        ),
      );
      final failure = (result as Left<Failure, int>).value;
      expect(failure, isA<AuthFailure>());
      expect(failure.message, 'انتهت صلاحية الجلسة');
    });

    test('CacheException maps to CacheFailure', () async {
      final result = await executeWithHandling<int>(
        () async => throw const CacheException('disk full'),
      );
      final failure = (result as Left<Failure, int>).value;
      expect(failure, isA<CacheFailure>());
      expect(failure.message, 'disk full');
    });

    test('unknown exception maps to a generic message and leaks nothing',
        () async {
      final result = await executeWithHandling<int>(
        () async => throw Exception('SECRET /internal/path xyz'),
      );
      final failure = (result as Left<Failure, int>).value;
      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'An unexpected error occurred');
      expect(failure.message, isNot(contains('SECRET')));
    });
  });
}

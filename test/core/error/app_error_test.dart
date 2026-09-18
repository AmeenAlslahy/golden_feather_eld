import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';

void main() {
  group('AppError — common behavior', () {
    test('has required fields', () {
      const error = NetworkError(
        code: 'network.timeout',
        l10nKey: 'networkTimeout',
      );

      expect(error.code, 'network.timeout');
      expect(error.l10nKey, 'networkTimeout');
      expect(error.severity, ErrorSeverity.warning);
      expect(error.cause, isNull);
      expect(error.stackTrace, isNull);
      expect(error.context, isNull);
    });

    test('toString includes type and code', () {
      const error = NetworkError(
        code: 'network.timeout',
        l10nKey: 'networkTimeout',
      );

      expect(error.toString(), contains('NetworkError'));
      expect(error.toString(), contains('network.timeout'));
    });

    test('== compares by type + code + l10nKey + severity', () {
      const a = NetworkError(code: 'x', l10nKey: 'y');
      const b = NetworkError(code: 'x', l10nKey: 'y');
      const c = NetworkError(code: 'z', l10nKey: 'y');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('same code but different subclass are NOT equal', () {
      const a = NetworkError(code: 'x', l10nKey: 'y');
      const b = AuthError(code: 'x', l10nKey: 'y');

      expect(a, isNot(equals(b)));
    });

    test('withContext merges into existing context', () {
      const base = NetworkError(
        code: 'x',
        l10nKey: 'y',
        context: {'endpoint': '/eld/status'},
      );

      final enriched = base.withContext({'attempt': 3});

      expect(enriched.context, {
        'endpoint': '/eld/status',
        'attempt': 3,
      });
    });

    test('withContext overwrites existing keys', () {
      const base = NetworkError(
        code: 'x',
        l10nKey: 'y',
        context: {'attempt': 1},
      );

      final enriched = base.withContext({'attempt': 2});

      expect(enriched.context, {'attempt': 2});
    });

    test('withCause attaches cause + stack trace', () {
      const base = NetworkError(code: 'x', l10nKey: 'y');
      final stack = StackTrace.current;
      final cause = Exception('boom');

      final enriched = base.withCause(cause, stack);

      expect(enriched.cause, same(cause));
      expect(enriched.stackTrace, same(stack));
    });

    test('withContext preserves original error type', () {
      const base = AuthError(code: 'x', l10nKey: 'y');
      final enriched = base.withContext({'foo': 'bar'});

      expect(enriched, isA<AuthError>());
    });
  });

  group('AppError — subclasses', () {
    test('AuthError has warning severity', () {
      const error = AuthError(code: 'x', l10nKey: 'y');
      expect(error.severity, ErrorSeverity.warning);
    });

    test('SessionExpiredError has default code + l10nKey', () {
      const error = SessionExpiredError();
      expect(error.code, 'auth.session.expired');
      expect(error.l10nKey, 'sessionExpired');
    });

    test('PermissionError has default code + l10nKey', () {
      const error = PermissionError();
      expect(error.code, 'auth.forbidden');
      expect(error.l10nKey, 'permissionDenied');
    });

    test('NotFoundError has default code + l10nKey', () {
      const error = NotFoundError();
      expect(error.code, 'resource.notFound');
      expect(error.l10nKey, 'notFound');
    });

    test('ValidationError carries field errors', () {
      const error = ValidationError(
        code: 'validation.failed',
        l10nKey: 'validationFailed',
        fieldErrors: {'email': 'emailInvalid', 'password': 'passwordTooShort'},
      );

      expect(error.fieldErrors, hasLength(2));
      expect(error.fieldErrors!['email'], 'emailInvalid');
    });

    test('UnsupportedCapabilityError carries capability name', () {
      const error = UnsupportedCapabilityError(
        capability: 'hos.reports',
      );

      expect(error.capability, 'hos.reports');
      expect(error.severity, ErrorSeverity.error);
    });

    test('ServerError carries status code', () {
      const error = ServerError(
        code: 'server.500',
        statusCode: 500,
      );

      expect(error.statusCode, 500);
      expect(error.severity, ErrorSeverity.error);
    });

    test('TimeUnavailableError has default code', () {
      const error = TimeUnavailableError();
      expect(error.code, 'time.unavailable');
      expect(error.severity, ErrorSeverity.error);
    });

    test('UnknownError has fatal severity', () {
      const error = UnknownError(code: 'unknown');
      expect(error.severity, ErrorSeverity.fatal);
    });
  });

  group('AppError — sealed pattern matching', () {
    test('exhaustive switch works', () {
      AppError error = const NetworkError(code: 'x', l10nKey: 'y');

      final label = switch (error) {
        NetworkError() => 'network',
        AuthError() => 'auth',
        SessionExpiredError() => 'session',
        ValidationError() => 'validation',
        PermissionError() => 'permission',
        NotFoundError() => 'notFound',
        ConflictError() => 'conflict',
        UnsupportedCapabilityError() => 'unsupported',
        ServerError() => 'server',
        TimeUnavailableError() => 'time',
        StorageError() => 'storage',
        SyncError() => 'sync',
        UnknownError() => 'unknown',
      };

      expect(label, 'network');
    });
  });
}

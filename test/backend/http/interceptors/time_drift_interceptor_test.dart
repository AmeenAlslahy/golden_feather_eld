import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/http/interceptors/time_drift_interceptor.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';

/// Builds a dio [Response] with an optional HTTP Date header.
/// The key is stored lowercase to be robust against Headers normalisation.
Response _response(String path, {String? dateHeader, int statusCode = 200}) {
  final headers = <String, List<String>>{};
  if (dateHeader != null) headers['date'] = [dateHeader];
  return Response(
    requestOptions: RequestOptions(path: path),
    statusCode: statusCode,
    headers: Headers.fromMap(headers),
    data: {},
  );
}

TrustedTimeAvailable _anchoredUtc(TrustedTimeProvider provider) {
  final result = provider.currentTime;
  expect(result, isA<TrustedTimeAvailable>());
  return result as TrustedTimeAvailable;
}

void main() {
  group('TimeDriftInterceptor', () {
    late FakeTrustedTimeProvider timeProvider;
    late TimeDriftInterceptor interceptor;

    setUp(() {
      timeProvider = FakeTrustedTimeProvider();
      interceptor = TimeDriftInterceptor(timeProvider: timeProvider);
    });

    test('first response with a Date header anchors trusted time', () {
      final serverUtc = DateTime.utc(2026, 9, 23, 10, 0);
      interceptor.onResponse(
        _response('/api/health', dateHeader: serverUtc._httpDate()),
        ResponseInterceptorHandler(),
      );
      expect(_anchoredUtc(timeProvider).utc, serverUtc);
    });

    test('small drift within the resync interval does NOT re-anchor', () {
      final t0 = DateTime.utc(2026, 9, 23, 10, 0);
      interceptor.onResponse(
        _response('/a', dateHeader: t0._httpDate()),
        ResponseInterceptorHandler(),
      );
      // 10s of "server time" drift: below the 30s tolerance and the
      // local elapsed time is far below the 5-minute interval.
      final t1 = t0.add(const Duration(seconds: 10));
      interceptor.onResponse(
        _response('/b', dateHeader: t1._httpDate()),
        ResponseInterceptorHandler(),
      );
      expect(_anchoredUtc(timeProvider).utc, t0);
    });

    test('drift beyond the tolerance re-anchors', () {
      final t0 = DateTime.utc(2026, 9, 23, 10, 0);
      interceptor.onResponse(
        _response('/a', dateHeader: t0._httpDate()),
        ResponseInterceptorHandler(),
      );
      final t1 = t0.add(const Duration(seconds: 45));
      interceptor.onResponse(
        _response('/b', dateHeader: t1._httpDate()),
        ResponseInterceptorHandler(),
      );
      expect(_anchoredUtc(timeProvider).utc, t1);
    });

    test('error responses with a Date header also calibrate', () {
      final serverUtc = DateTime.utc(2026, 9, 23, 11, 0);
      final response = _response(
        '/api/eld/logs',
        dateHeader: serverUtc._httpDate(),
        statusCode: 500,
      );
      interceptor.onError(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
        ),
        _errorHandler(),
      );
      expect(_anchoredUtc(timeProvider).utc, serverUtc);
    });

    test('error without a response leaves the clock untouched', () {
      interceptor.onError(
        DioException(
          requestOptions: RequestOptions(path: '/api/eld/logs'),
          type: DioExceptionType.connectionTimeout,
        ),
        _errorHandler(),
      );
      expect(timeProvider.state, TrustedTimeState.uninitialized);
    });

    test('response without a Date header is ignored', () {
      interceptor.onResponse(
        _response('/api/health'),
        ResponseInterceptorHandler(),
      );
      expect(timeProvider.state, TrustedTimeState.uninitialized);
    });

    test('invalid Date header is ignored without crashing', () {
      interceptor.onResponse(
        _response('/api/health', dateHeader: 'not-a-valid-date'),
        ResponseInterceptorHandler(),
      );
      expect(timeProvider.state, TrustedTimeState.uninitialized);
    });

    // Note: the 5-minute maximum resync interval branch measures local
    // elapsed time with the real DateTime.now(); it is not unit-testable
    // without a clock seam. The 30s tolerance branch above covers the
    // re-anchoring path.
  });
}

extension on DateTime {
  String _httpDate() => HttpDate.format(this);
}

/// dio's error handler completes its future with the error; ignore it so the
/// test zone does not see an unhandled async error.
ErrorInterceptorHandler _errorHandler() {
  final handler = ErrorInterceptorHandler();
  // ignore: invalid_use_of_protected_member
  handler.future.ignore();
  return handler;
}

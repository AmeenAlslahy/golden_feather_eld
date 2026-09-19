import 'dart:io';
import 'package:dio/dio.dart';
import '../../time/trusted_time_provider.dart';
import '../../utils/logger.dart';

/// Intercepts successful HTTP responses and updates the TrustedTimeProvider
/// with the server's time (from the Date header).
class TimeDriftInterceptor extends Interceptor {
  final TrustedTimeProvider timeProvider;

  TimeDriftInterceptor({required this.timeProvider});

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _processDateHeader(response);
    super.onResponse(response, handler);
  }

  void _processDateHeader(Response response) {
    final dateHeader = response.headers.value(HttpHeaders.dateHeader);
    if (dateHeader == null || dateHeader.isEmpty) return;

    try {
      final serverUtc = HttpDate.parse(dateHeader).toUtc();
      
      // If we haven't synced yet, or we want to resync periodically
      timeProvider.anchor(serverUtc);
      AppLogger.info('Anchored trusted time to server Date header: $serverUtc');
    } catch (e) {
      AppLogger.warning('Failed to parse Date header: $dateHeader, error: $e');
    }
  }
}

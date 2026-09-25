import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/time/trusted_time_provider.dart';
import '../../../core/utils/logger.dart';

/// Intercepts successful HTTP responses and updates the TrustedTimeProvider
/// with the server's time (from the Date header).
///
/// الثبات (throttling): لا نعيد ضبط المحور عند كل استجابة — كل استجابة بإحداث
/// Second تقريبية كانت تسبب اهتزازاً ±500ms في كل طلب، ويكفي أن نعيد الضبط
/// عند انجراف يتجاوز 30 ثانية أو كل 5 دقائق كحد أقصى.
class TimeDriftInterceptor extends Interceptor {
  final TrustedTimeProvider timeProvider;

  DateTime? _lastServerUtc;
  DateTime? _lastAnchorLocal;

  static const Duration _minResyncInterval = Duration(minutes: 5);
  static const Duration _driftTolerance = Duration(seconds: 30);

  TimeDriftInterceptor({required this.timeProvider});

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _processDateHeader(response);
    super.onResponse(response, handler);
  }

  /// رؤوس الاستجابات الخطأ تحوي Date صالحاً أيضاً — عند فشل الشبكة المتكرر
  /// قد تكون هذه هي الفرص الوحيدة للمعايرة.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response != null) _processDateHeader(response);
    super.onError(err, handler);
  }

  void _processDateHeader(Response response) {
    final dateHeader = response.headers.value(HttpHeaders.dateHeader);
    if (dateHeader == null || dateHeader.isEmpty) return;

    DateTime serverUtc;
    try {
      serverUtc = HttpDate.parse(dateHeader).toUtc();
    } catch (e) {
      AppLogger.warning('Failed to parse Date header: $dateHeader, error: $e');
      return;
    }

    final lastServer = _lastServerUtc;
    final lastLocal = _lastAnchorLocal;
    if (lastServer != null && lastLocal != null) {
      final now = DateTime.now().toUtc();
      final expected = lastServer.add(now.difference(lastLocal));
      final drift = serverUtc.difference(expected).abs();
      if (drift < _driftTolerance &&
          now.difference(lastLocal) < _minResyncInterval) {
        return;
      }
    }

    timeProvider.anchor(serverUtc);
    _lastServerUtc = serverUtc;
    _lastAnchorLocal = DateTime.now().toUtc();
    AppLogger.info('Anchored trusted time to server Date header: $serverUtc');
  }
}

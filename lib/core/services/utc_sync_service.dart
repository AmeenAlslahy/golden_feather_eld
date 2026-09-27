import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';

/// خدمة مزامنة التوقيت مع UTC
class UtcSyncService {
  Duration? _drift; // انحراف الوقت المحلي

  /// مزامنة الوقت مع مرجع الخادم.
  ///
  /// الانحراف لا يُحسب من ساعة الجهاز نفسها — الصيغة القديمة
  /// (`now.toUtc().difference(now)`) كانت تعيد صفرًا دائمًا، أي أن
  /// "مزامنة" لا تفعل شيئًا كانت تسجّل نفسها ناجحة. بدون زمن خادم
  /// مرجعي لا نَدّعي مزامنة الآن. المصدر الموثوق الوحيد للزمن هو
  /// ترويسة Date عبر TimeDriftInterceptor.
  Future<void> syncWithUtc({DateTime? serverTime}) async {
    final now = DateTime.now();
    if (serverTime == null) {
      AppLogger.warning(
          'UTC sync skipped: no server reference time (device clock must not anchor trusted time)');
      return;
    }
    try {
      _drift = serverTime.toUtc().difference(now);

      AppLogger.info(
          '🕐 UTC Sync: server=${serverTime.toUtc().toIso8601String()}');
      AppLogger.info('   Local: ${now.toIso8601String()}');
      AppLogger.info('   Drift: ${_drift?.inSeconds}s');
    } catch (e) {
      AppLogger.error('UTC Sync failed', e);
    }
  }

  /// الحصول على الوقت الحالي المتزامن
  DateTime get syncedTime {
    final now = DateTime.now();
    if (_drift != null) {
      return now.add(_drift!);
    }
    return now;
  }

  /// الحصول على الوقت بصيغة UTC
  DateTime get utcNow => syncedTime.toUtc();
}

/// مزود خدمة UTC
final utcSyncServiceProvider = Provider<UtcSyncService>((ref) {
  return UtcSyncService();
});

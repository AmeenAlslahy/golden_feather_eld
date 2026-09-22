import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ntp/ntp.dart';
import '../time/trusted_time_provider.dart';
import '../utils/logger.dart';

/// خدمة مزامنة التوقيت مع UTC
class UtcSyncService {
  final TrustedTimeProvider timeProvider;
  
  DateTime? _lastSyncTime;
  Duration? _drift; // انحراف الوقت المحلي

  UtcSyncService({required this.timeProvider});

  /// مزامنة الوقت مع UTC
  Future<void> syncWithUtc() async {
    try {
      final now = DateTime.now();
      
      final int offset = await NTP.getNtpOffset(
        localTime: now,
        lookUpAddress: 'time.google.com',
      );
      
      _drift = Duration(milliseconds: offset);
      _lastSyncTime = now;
      
      final trueUtc = now.add(_drift!).toUtc();
      timeProvider.anchor(trueUtc);

      AppLogger.info('🕐 UTC Sync via NTP: ${trueUtc.toIso8601String()}');
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

  /// تنسيق الوقت للتخزين
  String formatForStorage(DateTime time) {
    return time.toUtc().toIso8601String();
  }

  /// استخراج الوقت من التخزين
  DateTime parseFromStorage(String stored) {
    return DateTime.parse(stored).toLocal();
  }

  /// معلومات المزامنة للتقرير
  Map<String, dynamic> getSyncInfo() {
    return {
      'last_sync': _lastSyncTime?.toIso8601String(),
      'drift_seconds': _drift?.inSeconds,
      'is_synced': _lastSyncTime != null,
      'timezone': DateTime.now().timeZoneName,
      'utc_offset': DateTime.now().timeZoneOffset.inHours,
    };
  }
}

/// مزود خدمة UTC
final utcSyncServiceProvider = Provider<UtcSyncService>((ref) {
  return UtcSyncService(timeProvider: ref.watch(trustedTimeProvider));
});

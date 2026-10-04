import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';

/// Represents the detailed state of the time trust.
enum TrustedTimeState { uninitialized, trusted, stale, invalid, unavailable }

/// Sealed class for time result to force callers to handle untrusted time explicitly.
sealed class TrustedTimeResult {}

class TrustedTimeAvailable extends TrustedTimeResult {
  final DateTime utc;
  TrustedTimeAvailable(this.utc);
}

class TrustedTimeUnavailable extends TrustedTimeResult {
  final TrustedTimeState state;
  TrustedTimeUnavailable(this.state);
}

abstract interface class TrustedTimeProvider {
  /// The current state of trust.
  TrustedTimeState get state;

  /// Returns a safe result representing whether trusted UTC is available.
  TrustedTimeResult get currentTime;

  /// Returns monotonic elapsed duration since anchor. (0 if not anchored yet).
  Duration get monotonicElapsed;

  /// Anchors the provider to a trusted server time.
  void anchor(DateTime serverUtc);
}

/// A production implementation that uses a monotonic Stopwatch.
///
/// **الاستمرارية عبر الإقلاع (قرار المالك 2026-10-03):** آخر مرساة خادمية
/// تُخزَّن محلياً مع ساعة الجهاز لحظتها، وتُستعاد عند الإقلاع بإزاحة
/// ساعة الجهاز عبر فترة الإغلاق — الوقت يبقى موثوقاً داخل حد الـ 7
/// أيام (يُقاس بساعة الجهاز عبر الفترة). ملاحظة أمنية معلنة: هذا يجعل
/// ساعة الجهاز مرجعَ الفترة offline فقط، والخادم يصالح الطوابع عند
/// المزامنة. مرساة خادمية جديدة تلغي الاستعادة فوراً.
class MonotonicTrustedTimeProvider implements TrustedTimeProvider {
  final Stopwatch _stopwatch = Stopwatch();
  DateTime? _trustedServerUtcAtSync;
  DateTime? _restoredAnchorUtc;
  DateTime? _restoredDeviceWallMs;
  bool _restoredFromDisk = false;

  final String? Function()? _readPersistedAnchor;
  final void Function(String)? _writePersistedAnchor;

  MonotonicTrustedTimeProvider({
    String? Function()? readPersistedAnchor,
    void Function(String)? writePersistedAnchor,
  }) : _readPersistedAnchor = readPersistedAnchor,
       _writePersistedAnchor = writePersistedAnchor {
    _restore();
  }

  void _restore() {
    final json = _readPersistedAnchor?.call();
    if (json == null || json.isEmpty) return;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final anchorUtc = DateTime.tryParse(map['anchorUtc'] as String? ?? '');
      final deviceWallMs = (map['deviceWallMs'] as num?)?.toInt();
      if (anchorUtc == null || deviceWallMs == null) return;
      final restoredDeviceWall = DateTime.fromMillisecondsSinceEpoch(
        deviceWallMs,
      );
      _restoredAnchorUtc = anchorUtc;
      _restoredDeviceWallMs = restoredDeviceWall;
      _restoredFromDisk = true;
      // بذر الساعة: مرساة الخادم + إزاحة ساعة الجهاز عبر فترة الإغلاق —
      // ثم يكمل الـ Stopwatch بشكل monotonic من لحظة الإقلاع.
      _trustedServerUtcAtSync = anchorUtc.add(
        DateTime.now().difference(restoredDeviceWall),
      );
      _stopwatch.start();
    } catch (_) {
      // مرساة تالفة تُتجاهل — تبقى uninitialized حتى مرساة خادمية.
    }
  }

  @override
  TrustedTimeState get state {
    if (_trustedServerUtcAtSync == null) return TrustedTimeState.uninitialized;

    if (_restoredFromDisk && _restoredDeviceWallMs != null) {
      // حد الثبات للنسخة المستعادة يُقاس عبر فترة الإغلاق بساعة الجهاز.
      if (DateTime.now().difference(_restoredDeviceWallMs!) >=
          const Duration(days: 7)) {
        return TrustedTimeState.stale;
      }
      return TrustedTimeState.trusted;
    }

    // For now, if offline for more than 7 days, consider stale.
    if (_stopwatch.elapsed.inDays >= 7) return TrustedTimeState.stale;

    return TrustedTimeState.trusted;
  }

  @override
  void anchor(DateTime serverUtc) {
    _trustedServerUtcAtSync = serverUtc.toUtc();
    _restoredFromDisk = false;
    _restoredAnchorUtc = null;
    _restoredDeviceWallMs = null;
    _stopwatch.reset();
    _stopwatch.start();
    try {
      _writePersistedAnchor?.call(
        jsonEncode({
          'anchorUtc': _trustedServerUtcAtSync!.toIso8601String(),
          'deviceWallMs': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    } catch (_) {
      // فشل التخزين لا يفسد المرساة داخل الجلسة.
    }
  }

  @override
  TrustedTimeResult get currentTime {
    final currentState = state;
    if (currentState != TrustedTimeState.trusted) {
      return TrustedTimeUnavailable(currentState);
    }

    return TrustedTimeAvailable(
      _trustedServerUtcAtSync!.add(_stopwatch.elapsed),
    );
  }

  /// وقت آخر مرساة خادمية كما قُرئت من التخزين (تشخيصياً).
  DateTime? get restoredAnchorUtc => _restoredAnchorUtc;

  @override
  Duration get monotonicElapsed => _stopwatch.elapsed;
}

/// A fake implementation for deterministic testing.
class FakeTrustedTimeProvider implements TrustedTimeProvider {
  DateTime? _mockUtcTime;
  TrustedTimeState _state = TrustedTimeState.uninitialized;
  Duration _monotonicElapsed = Duration.zero;

  FakeTrustedTimeProvider({
    DateTime? initialUtcTime,
    TrustedTimeState initialState = TrustedTimeState.uninitialized,
  }) {
    if (initialUtcTime != null) {
      _mockUtcTime = initialUtcTime.toUtc();
      _state = initialState == TrustedTimeState.uninitialized
          ? TrustedTimeState.trusted
          : initialState;
    } else {
      _state = initialState;
    }
  }

  @override
  TrustedTimeState get state => _state;

  @override
  TrustedTimeResult get currentTime {
    if (_state != TrustedTimeState.trusted || _mockUtcTime == null) {
      return TrustedTimeUnavailable(_state);
    }
    return TrustedTimeAvailable(_mockUtcTime!);
  }

  @override
  Duration get monotonicElapsed => _monotonicElapsed;

  @override
  void anchor(DateTime serverUtc) {
    _mockUtcTime = serverUtc.toUtc();
    _state = TrustedTimeState.trusted;
    _monotonicElapsed = Duration.zero;
  }

  /// TEST ONLY: Advance the fake clock.
  void advance(Duration duration) {
    if (_mockUtcTime != null) {
      _mockUtcTime = _mockUtcTime!.add(duration);
    }
    _monotonicElapsed += duration;
  }

  /// TEST ONLY: Set state manually.
  void setState(TrustedTimeState newState) {
    _state = newState;
  }
}

final trustedTimeProvider = Provider<TrustedTimeProvider>((ref) {
  // قراءة كسلية متسامحة: بيئة بلا تخزين مهيأ (بعض الاختبارات) تعيد null
  // بدل انهيار — المزود يبقى uninitialized حتى أول مرساة خادمية.
  String? readAnchor() {
    try {
      return ref
          .read(localStorageProvider)
          .prefs
          .getString('trusted_time_anchor');
    } catch (_) {
      return null;
    }
  }

  void writeAnchor(String json) {
    try {
      ref
          .read(localStorageProvider)
          .prefs
          .setString('trusted_time_anchor', json);
    } catch (_) {
      // لا تخزين متاح — المرساة تبقى داخل الجلسة فقط.
    }
  }

  return MonotonicTrustedTimeProvider(
    readPersistedAnchor: readAnchor,
    writePersistedAnchor: writeAnchor,
  );
});

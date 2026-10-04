import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';

/// إثبات استمرارية مرساة الوقت عبر الإقلاع (قرار المالك 2026-10-03):
/// آخر مرساة خادمية تُخزَّن مع ساعة الجهاز لحظتها، وتُستعاد بإزاحة
/// ساعة الجهاز عبر فترة الإغلاق، داخل حد الثبات 7 أيام.
void main() {
  test('restored anchor within 7 days is trusted and tracks device delta',
      () async {
    String? persisted;
    final provider = MonotonicTrustedTimeProvider(
      readPersistedAnchor: () => persisted,
      writePersistedAnchor: (json) => persisted = json,
    );

    final anchorWall = DateTime.now().subtract(const Duration(hours: 2));
    provider.anchor(
      anchorWall.add(const Duration(hours: 2)), // مرساة خادمية صحيحة
    );
    expect(persisted, isNotNull);

    // إقلاع جديد: مزود يقرأ نفس المرساة المخزنة.
    final restored = MonotonicTrustedTimeProvider(
      readPersistedAnchor: () => persisted,
      writePersistedAnchor: (json) => persisted = json,
    );

    expect(restored.state, TrustedTimeState.trusted);
    final now = restored.currentTime;
    expect(now, isA<TrustedTimeAvailable>());
    // الوقت المشتق قريب من الآن الحقيقي (ساعة الجهاز مستقرة في الاختبار).
    final utc = (now as TrustedTimeAvailable).utc;
    expect(
      DateTime.now().toUtc().difference(utc).abs(),
      lessThan(const Duration(minutes: 5)),
    );
  });

  test('restored anchor older than 7 days goes stale', () async {
    final deviceWall = DateTime.now().subtract(const Duration(days: 8));
    final persisted =
        '{"anchorUtc": "${deviceWall.add(const Duration(hours: 2)).toIso8601String()}", "deviceWallMs": ${deviceWall.millisecondsSinceEpoch}}';

    final restored = MonotonicTrustedTimeProvider(
      readPersistedAnchor: () => persisted,
      writePersistedAnchor: (json) {},
    );

    expect(restored.state, TrustedTimeState.stale);
    expect(restored.currentTime, isA<TrustedTimeUnavailable>());
  });

  test('corrupted persisted anchor is ignored — stays uninitialized', () {
    final restored = MonotonicTrustedTimeProvider(
      readPersistedAnchor: () => '{broken json',
      writePersistedAnchor: (json) {},
    );

    expect(restored.state, TrustedTimeState.uninitialized);
    expect(restored.currentTime, isA<TrustedTimeUnavailable>());
  });

  test('fresh server anchor clears the restored state and re-persists', () {
    final hourAgo = DateTime.now().subtract(const Duration(hours: 1));
    var persisted =
        '{"anchorUtc": "${hourAgo.add(const Duration(hours: 2)).toIso8601String()}", "deviceWallMs": ${hourAgo.millisecondsSinceEpoch}}';
    final provider = MonotonicTrustedTimeProvider(
      readPersistedAnchor: () => persisted,
      writePersistedAnchor: (json) => persisted = json,
    );
    expect(provider.state, TrustedTimeState.trusted); // restored within bound

    provider.anchor(DateTime.utc(2026, 10, 3, 12));

    expect(provider.state, TrustedTimeState.trusted);
    expect(persisted, contains('2026-10-03'));
  });
}

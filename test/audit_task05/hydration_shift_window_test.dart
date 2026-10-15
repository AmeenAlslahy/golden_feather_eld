/// انحدار: نافذة الوردية (14 ساعة) كانت تنهار إلى الصفر بعد إعادة التشغيل.
///
/// ### العطل
///
/// `hydrateFromPeriods` كان يلتقط `firstDutyStart` من **أول فترة عمل في
/// كامل السجل** بلا أي حدّ زمني، بينما تراكم العدّادات نفسه كان مقيَّداً
/// بـ `cycleStart` (آخر 8 أيام).
///
/// ### الأثر
///
/// سائق يعمل اليوم، كانت أول فترة عمل له **قبل ثمانية أيام**:
/// ```text
/// _shiftStartTime = قبل 8 أيام
/// remainingShift = 14h − 8 أيام ⇒ يُصفَّر عند الصفر
/// ```
/// فيرى السائق **صفراً** على نافذة الوردية = مخالفة ورقية **مُختلَقة**
/// لم يخطئ فيها شيئاً. والأسوأ أنه يظهر **فقط** عند إعادة التشغيل،
/// فيبدو عطلاً متقطّعاً لا علاقة له بأفعاله.
///
/// ### القاعدة (49 CFR 395.3(a)(1))
///
/// نافذة الـ14 ساعة تُعيد نفسها بعد كل راحة مؤهلة ≥ 10 ساعات متتالية.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_state_machine.dart';

void main() {
  final now = DateTime.utc(2026, 10, 14, 2, 0);

  HosStateMachine machineAt(DateTime utc) =>
      HosStateMachine(FakeTrustedTimeProvider(initialUtcTime: utc));

  DutyPeriod period(
    String status, {
    required DateTime start,
    required DateTime end,
  }) =>
      DutyPeriod(
        status: status,
        startTime: start,
        endTime: end,
      );

  void hydrate(HosStateMachine sm, List<DutyPeriod> periods) {
    sm.hydrateFromPeriods(
      periods: periods,
      now: now,
      shiftWindow: const Duration(hours: 14),
      cycleWindow: const Duration(days: 8),
    );
  }

  group('نافذة الوردية لا تتمدد عبر الراحة الطويلة', () {
    test('❌ كان: عمل قبل 8 أيام ⇒ صفر متبقٍّ (مخالفة مُختلَقة)', () {
      // هذا هو العطل كما كان يُوصف.
      final shiftStart = now.subtract(const Duration(days: 8));
      final elapsedHours = now.difference(shiftStart).inHours;
      expect(elapsedHours, greaterThan(const Duration(hours: 14).inHours));
      expect(const Duration(hours: 14) - Duration(hours: elapsedHours), const Duration(hours: -178));
    });

    test('✅ عمل اليوم ⇒ نافذة الوردية تبدأ من أول عمل اليوم', () {
      final sm = machineAt(now);
      final workStart = now.subtract(const Duration(hours: 6));

      hydrate(sm, [
        period('ON_DUTY', start: workStart, end: workStart.add(const Duration(hours: 6))),
      ]);

      expect(sm.shiftStartTime, workStart,
          reason: 'ست ساعات عمل ⇒ المتبقي ثماني ساعات');
      expect(
        const Duration(hours: 14) - now.difference(sm.shiftStartTime),
        const Duration(hours: 8),
      );
    });

    test('✅ راحة ≥ 10h تعيد تشغيل النافذة من بعدها', () {
      final sm = machineAt(now);

      // عمل امس، ثم راحة 12 ساعة (≥10 و<34)، ثم عمل اليوم.
      //
      // ⚠️ الراحة هنا **12 ساعة لا 70**: فـ 70 ساعة تُشغّل قاعدة إعادة
      // التصفير الأسبوعي (34h) التي تُصفّر الدورة وتبدأ النافذة من الآن —
      // سلوك صحيح آخر، ولكلٍّ اختباره.
      final yesterdayWork = now.subtract(const Duration(hours: 26));
      final restStart = now.subtract(const Duration(hours: 14));
      final todayWork = now.subtract(const Duration(hours: 2));

      hydrate(sm, [
        period('ON_DUTY',
            start: yesterdayWork, end: yesterdayWork.add(const Duration(hours: 12))),
        period('OFF_DUTY',
            start: restStart, end: restStart.add(const Duration(hours: 12))),
        period('ON_DUTY', start: todayWork, end: todayWork.add(const Duration(hours: 2))),
      ]);

      expect(sm.shiftStartTime, todayWork,
          reason: 'الراحة المؤهلة ألغت نافذة العمل القديمة');
      expect(
        const Duration(hours: 14) - now.difference(sm.shiftStartTime),
        const Duration(hours: 12),
      );
    });

    test('✅ راحة ≥ 34h تُشغّل إعادة التصفير الأسبوعي (70/8)', () {
      // 49 CFR 395.3(a)(ii): 34 ساعة راحة متتالية ⇒ دورة 8 أيام جديدة.
      // وتبدأ نافذة الوردية من الآن (لا من آخر عمل قبل الراحة الطويلة).
      final sm = machineAt(now);
      final oldWork = now.subtract(const Duration(days: 3, hours: 2));
      final restStart = now.subtract(const Duration(days: 3));
      final todayWork = now.subtract(const Duration(hours: 2));

      hydrate(sm, [
        period('ON_DUTY', start: oldWork, end: restStart),
        period('OFF_DUTY',
            start: restStart, end: restStart.add(const Duration(days: 2, hours: 20))),
        period('ON_DUTY', start: todayWork, end: todayWork.add(const Duration(hours: 2))),
      ]);

      expect(sm.shiftStartTime, now,
          reason: 'إعادة تصفير أسبوعي ⇒ نافذة الوردية تبدأ الآن');
      expect(
        const Duration(hours: 14) - now.difference(sm.shiftStartTime),
        const Duration(hours: 14),
      );
    });

    test('✅ راحة < 10h لا تعيد تشغيل النافذة', () {
      final sm = machineAt(now);

      // عمل من أمس، استراحة 4 ساعات فقط، ثم عمل اليوم.
      final yesterday = now.subtract(const Duration(hours: 18));
      final restStart = now.subtract(const Duration(hours: 5));
      final nowWork = now.subtract(const Duration(hours: 1));

      hydrate(sm, [
        period('ON_DUTY', start: yesterday, end: yesterday.add(const Duration(hours: 13))),
        period('OFF_DUTY',
            start: restStart, end: restStart.add(const Duration(hours: 4))),
        period('ON_DUTY', start: nowWork, end: nowWork.add(const Duration(hours: 1))),
      ]);

      expect(sm.shiftStartTime, yesterday,
          reason: 'أربع ساعات راحة لا تكفي لإعادة تشغيل النافذة');
    });

    test('✅ سلسلة راحتين قصيرتين لا تتراكم عبر انتقال غير خدمة', () {
      // انتقال ON_DUTY ثم OFF_DUTY قصيراً ثم ON_DUTY: الفجوات القصيرة
      // يجب أن تبقى منفس نافذة الوردية (لاreset لكل انتقال).
      final sm = machineAt(now);
      final start = now.subtract(const Duration(hours: 9));

      hydrate(sm, [
        period('ON_DUTY', start: start, end: start.add(const Duration(hours: 2))),
        period('OFF_DUTY',
            start: start.add(const Duration(hours: 2)),
            end: start.add(const Duration(hours: 3))),
        period('ON_DUTY',
            start: start.add(const Duration(hours: 3)),
            end: start.add(const Duration(hours: 9))),
      ]);

      expect(sm.shiftStartTime, start);
      expect(
        const Duration(hours: 14) - now.difference(sm.shiftStartTime),
        const Duration(hours: 5),
      );
    });

    test('Sleepers = راحة مؤهلة أيضاً', () {
      final sm = machineAt(now);
      final oldWork = now.subtract(const Duration(days: 2));
      final restStart = now.subtract(const Duration(days: 1));
      final todayWork = now.subtract(const Duration(hours: 3));

      hydrate(sm, [
        period('ON_DUTY', start: oldWork, end: restStart),
        period('SLEEPER',
            start: restStart, end: restStart.add(const Duration(days: 1))),
        period('ON_DUTY', start: todayWork, end: now),
      ]);

      expect(sm.shiftStartTime, todayWork);
    });

    test('سائق جديد بلا سجل ⇒ النافذة تبدأ من الآن', () {
      final sm = machineAt(now);
      // لا فترات إطلاقاً — لا يمكن البناء بلا فترات، فنمرّر فارغة.
      hydrate(sm, const <DutyPeriod>[]);
      expect(sm.shiftStartTime, now,
          reason: 'لا نخترع بداية نافذة من فراغ');
    });
  });

  group('تراكم الدورة يبقى مقيَّداً بـ 8 أيام', () {
    test('القيادة خارج نافذة الدورة لا تُحتسب', () {
      final sm = machineAt(now);
      final old = now.subtract(const Duration(days: 20));

      hydrate(sm, [
        period('DRIVING', start: old, end: old.add(const Duration(hours: 6))),
        period('ON_DUTY', start: now.subtract(const Duration(hours: 1)), end: now),
      ]);

      // 6 ساعات قبل 20 يوماً خارج نافذة 8 أيام ⇒ لا تدخل العدّاد.
      expect(sm.totalDrivingHours, 0.0);
    });

    test('القيادة داخل نافذة الدورة تُحتسب', () {
      final sm = machineAt(now);
      final recent = now.subtract(const Duration(days: 2));

      hydrate(sm, [
        period('DRIVING', start: recent, end: recent.add(const Duration(hours: 6))),
        period('ON_DUTY', start: now.subtract(const Duration(hours: 1)), end: now),
      ]);

      expect(sm.totalDrivingHours, closeTo(6.0, 0.01));
    });
  });

  group('ترطيب فارغ أو تالف لا يكسر شيئاً', () {
    test('قائمة فارغة ⇒ لا تغيير', () {
      final sm = machineAt(now);
      final before = sm.shiftStartTime;
      hydrate(sm, const <DutyPeriod>[]);
      expect(sm.shiftStartTime, before);
    });

    test('فترة ينتهي قبل بدايتها تُتجاهل', () {
      final sm = machineAt(now);
      hydrate(sm, [
        period('ON_DUTY',
            start: now, end: now.subtract(const Duration(hours: 2))),
      ]);
      // لا انهيار، ولا نافذة وهمية من فترة مقلوبة.
      expect(sm.shiftStartTime, anyOf(now, isNull));
    });
  });
}
/// اتساق الأرقام المعروضة: الدائرة vs البطاقات vs الخادم.
///
/// ### العطلان
///
/// 1. **البطاقات لا تنزلق إطلاقاً.** كانت تعرض `indicator.value` الخام —
///    قيمة ثابتة من آخر جلب — بينما الدائرة تنقص في نفس اللحظة. فالتطبيق
///    يعرض رقمين مختلفين لنفس الحدّ القانوني على الشاشة نفسها.
///
/// 2. **الحدّ الحاكم محسوب على quantities غير قابلة للمقارنة.** كان الكود
///    يقارن `breakRemaining` (7:56، **متبقٍّ**) بـ `shiftUsed`
///    (10:12، **مستهلَك**) — كميّتان من حدّين مختلفين (8h و14h).
///    فالنتيجة أن الحدّ الحاكم صار الاستراحة (7:56) بينما الخادم يعرض
///    **3:48** (= 14:00 − 10:12). **فارق أربع ساعات** يمنح السائق رصيداً
///    قانونياً غير موجود.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/hos/presentation/widgets/status_dashboard/circular_timer_logic.dart';

/// لقمة خادم حقيقية — انظر `elapsed_reconciliation_test.dart` للمدخل الكامل.
StatusDashboard _server() => const StatusDashboard(
      driver: DriverRef(id: DriverId(2), name: 'Admin', displayText: 'Admin - 2'),
      operationalAlerts: OperationalAlerts(
        toolIcon: false,
        warningTriangleIcon: false,
        connectionStatus: ConnectionStatus.ok,
      ),
      currentDutyStatus: DutyStatusCode.onDutyNotDriving,
      remainingCircle: RemainingCircle(
        remaining: Duration(hours: 3, minutes: 48),
        label: 'Remaining',
        progress: 0.73,
      ),
      hosIndicators: HosIndicators(
        drive: HosIndicator(
            label: 'DRIVE', value: Duration(minutes: 4), type: IndicatorType.used),
        shift: HosIndicator(
            label: 'SHIFT', value: Duration(hours: 10, minutes: 12), type: IndicatorType.used),
        breakTime: HosIndicator(
            label: 'BREAK', value: Duration(hours: 7, minutes: 56), type: IndicatorType.remaining),
        cycle: HosIndicator(
            label: 'CYCLE', value: Duration(hours: 25, minutes: 41), type: IndicatorType.used),
      ),
      regulatoryConstraints: RegulatoryConstraints(ruleSet: CycleRule.usa70_8, limits: []),
    );

Duration _circle(Duration elapsed) => CircularTimerLogic.calculateUiState(
      circle: _server().remainingCircle,
      dutyStatus: DutyStatusCode.onDutyNotDriving,
      hosIndicators: _server().hosIndicators,
      statusLabel: 'ON_DUTY',
      elapsedSinceSnapshot: elapsed,
    ).liveRemaining;

void main() {
  group('الحد الحاكم يُحسب على المتبقّي لا على القيم الخام', () {
    test('ON_DUTY: الوردية (3:48) هي الحاكمة — مطابقة للخادم', () {
      // الخادم: remainingCircle = 03:48 = 14:00 − 10:12 ⇒ الوردية حاكمة.
      expect(_circle(Duration.zero), const Duration(hours: 3, minutes: 48));
    });

    test('❌ السلوك الخاطئ كان يعطي 7:56 بدل 3:48', () {
      // موثَّق عمداً: لو عاد العطل يوماً فلن «يُصلح» بالتصحيح الخطأ.
      const serverSays = Duration(hours: 3, minutes: 48);
      const oldLogicPicked = Duration(hours: 7, minutes: 56);
      expect(oldLogicPicked - serverSays, const Duration(hours: 4, minutes: 8),
          reason: 'التطبيق كان يعرض أكثر من القانون بـ 4 ساعات و8 دقائق');
    });

    test('عندما تكون الاستراحة هي الأضيق تُختار هي', () {
      // shift used 1:00 ⇒ متبقٍّ 13:00. break remaining 2:00 ⇒ هي الأضيق.
      final d = _server().copyWith(
        hosIndicators: _server().hosIndicators.copyWith(
          shift: const HosIndicator(
              label: 'SHIFT', value: Duration(hours: 1), type: IndicatorType.used),
          breakTime: const HosIndicator(
              label: 'BREAK', value: Duration(hours: 2), type: IndicatorType.remaining),
        ),
      );
      final ui = CircularTimerLogic.calculateUiState(
        circle: d.remainingCircle,
        dutyStatus: DutyStatusCode.onDutyNotDriving,
        hosIndicators: d.hosIndicators,
        statusLabel: 'ON_DUTY',
        elapsedSinceSnapshot: Duration.zero,
      );
      expect(ui.liveRemaining, const Duration(hours: 2));
      expect(ui.progress, closeTo(0.75, 0.01)); // (8−2)/8
    });

    test('مؤشر SHIFT بنمط USED: المتبقّي = 14h ناقص المستخدم', () {
      // 10:12 مستهلك ⇒ المتبقي 3:48، وهو نفسه ما يعرضه الخادم.
      final d = _server();
      expect(const Duration(hours: 14) - d.hosIndicators.shift.value,
          d.remainingCircle.remaining);
    });

    test('مؤشر DRIVING: المتبقّي = 11h ناقص القيادة', () {
      final d = _server().copyWith(
        hosIndicators: _server().hosIndicators.copyWith(
          drive: const HosIndicator(
              label: 'DRIVE', value: Duration(hours: 10), type: IndicatorType.used),
        ),
      );
      final ui = CircularTimerLogic.calculateUiState(
        circle: d.remainingCircle,
        dutyStatus: DutyStatusCode.driving,
        hosIndicators: d.hosIndicators,
        statusLabel: 'DRIVING',
        elapsedSinceSnapshot: Duration.zero,
      );
      expect(ui.liveRemaining, const Duration(hours: 1));
    });
  });

  group('البطاقات تنزلق بنفس عدّاد الدائرة', () {
    test('elapsed صفر ⇒ القيم كما وردت من الخادم', () {
      final live = CircularTimerLogic.liveIndicators(
        indicators: _server().hosIndicators,
        dutyStatus: DutyStatusCode.onDutyNotDriving,
        statusLabel: 'ON_DUTY',
        elapsedSinceSnapshot: Duration.zero,
      );
      expect(live.drive.value, const Duration(minutes: 4));
      expect(live.shift.value, const Duration(hours: 10, minutes: 12));
      expect(live.breakTime.value, const Duration(hours: 7, minutes: 56));
    });

    test('20 دقيقة ⇒ المستهلَك يزداد والمتبقٍ ينقص في العمل النشط', () {
      const gap = Duration(minutes: 20);
      final live = CircularTimerLogic.liveIndicators(
        indicators: _server().hosIndicators,
        dutyStatus: DutyStatusCode.onDutyNotDriving,
        statusLabel: 'ON_DUTY',
        elapsedSinceSnapshot: gap,
      );

      // في ON_DUTY: القيادة والاستراحة لا تتحركان (FMCSA § 395.3)
      expect(live.drive.value, const Duration(minutes: 4));
      expect(live.breakTime.value, const Duration(hours: 7, minutes: 56));
      // الوردية والدورة تتحركان مع استمرار الخدمة
      expect(live.shift.value, const Duration(hours: 10, minutes: 32));
      expect(live.cycle.value, const Duration(hours: 26, minutes: 1));
    });

    test('أثناء DRIVING: مؤشرات القيادة والاستراحة تنزلق أيضاً', () {
      const gap = Duration(minutes: 20);
      final live = CircularTimerLogic.liveIndicators(
        indicators: _server().hosIndicators,
        dutyStatus: DutyStatusCode.driving,
        statusLabel: 'DRIVING',
        elapsedSinceSnapshot: gap,
      );

      expect(live.drive.value, const Duration(minutes: 24));
      expect(live.shift.value, const Duration(hours: 10, minutes: 32));
      expect(live.breakTime.value, const Duration(hours: 7, minutes: 36));
      expect(live.cycle.value, const Duration(hours: 26, minutes: 1));
    });

    test('⚠️ بطاقة SHIFT والدائرة تقولا الشيء نفسه', () {
      // هذا هو الاتساق المطلوب: لا يعرض التطبيق رقمَين لنفس الحدّ.
      const gap = Duration(minutes: 20);
      final d = _server();
      final live = CircularTimerLogic.liveIndicators(
        indicators: d.hosIndicators,
        dutyStatus: DutyStatusCode.onDutyNotDriving,
        statusLabel: 'ON_DUTY',
        elapsedSinceSnapshot: gap,
      );

      final shiftRemainingFromCard = const Duration(hours: 14) - live.shift.value;
      final shiftRemainingFromCircle = _circle(gap);

      expect(shiftRemainingFromCard, shiftRemainingFromCircle);
      expect(shiftRemainingFromCard, const Duration(hours: 3, minutes: 28));
    });

    test('BREAK لا ينزل تحت الصفر أثناء القيادة', () {
      final live = CircularTimerLogic.liveIndicators(
        indicators: _server().hosIndicators,
        dutyStatus: DutyStatusCode.driving,
        statusLabel: 'DRIVING',
        elapsedSinceSnapshot: const Duration(hours: 12),
      );
      expect(live.breakTime.value, Duration.zero);
    });

    test('في الراحة لا يتحرّك شيء', () {
      for (final rest in [
        DutyStatusCode.offDuty,
        DutyStatusCode.sleeperBerth,
        DutyStatusCode.personalConveyance,
      ]) {
        final live = CircularTimerLogic.liveIndicators(
          indicators: _server().hosIndicators,
          dutyStatus: rest,
          statusLabel: 'rest',
          elapsedSinceSnapshot: const Duration(hours: 3),
        );
        expect(live.shift.value, const Duration(hours: 10, minutes: 12),
            reason: 'لا عمل ولا قيادة في الراحة ⇒ لا استهلاك');
        expect(live.drive.value, const Duration(minutes: 4));
      }
    });

    test('الدائرة نفسها لا تنزل تحت الصفر بسبب مرور الوقت', () {
      expect(_circle(const Duration(hours: 9)), Duration.zero);
      expect(_circle(const Duration(hours: 4)), Duration.zero);
    });

    test('قيمة الخادم السالبة (تجاوز حدّ) تُعرض كما وردت', () {
      // مثبَّت في main_circular_timer_test — وضع ثابت لا حالة عدّ تنازلي.
      final ui = CircularTimerLogic.calculateUiState(
        circle: const RemainingCircle(
          remaining: Duration(hours: -1, minutes: -30),
          label: 'Remaining',
          progress: 1,
        ),
        dutyStatus: null,
        hosIndicators: null,
        statusLabel: 'Driving',
        elapsedSinceSnapshot: Duration.zero,
      );
      expect(ui.liveRemaining, const Duration(hours: -1, minutes: -30));
    });
  });

  group('الدمج الأحادي الاتجاه: الخادم لا يسترجع وقتاً', () {
    const server = RemainingCircle(
      remaining: Duration(hours: 14),
      label: 'Remaining',
      progress: 0,
    );
    const localTight = RemainingCircle(
      remaining: Duration(hours: 8),
      label: 'Remaining',
      progress: 0.5,
    );

    test('خادم متأخر (يعرض أكثر) ⇒ نبقي الرقم المحلي', () {
      // ⚠️ الحالة المقيسة على الخادم الحيّ: SHIFT=00:00 بينما السائق
      // ON_DUTY منذ 12 ساعة. قبول 14:00 كان لقتل العدّاد كل 5 دقائق.
      final merged = CircularTimerLogic.reconcileRemaining(
        server: server,
        local: localTight,
        sameDutyEpisode: true,
      );
      expect(merged.remaining, const Duration(hours: 8));
    });

    test('خادم متقدّم (يعرض أقل) ⇒ نقبله فنضيق الوقت', () {
      const stricter = RemainingCircle(
        remaining: Duration(hours: 3),
        label: 'Remaining',
        progress: 0.8,
      );
      final merged = CircularTimerLogic.reconcileRemaining(
        server: stricter,
        local: localTight,
        sameDutyEpisode: true,
      );
      expect(merged.remaining, const Duration(hours: 3));
    });

    test('تغيّرت حالة الخدمة ⇒ الخادم بلا تحفّظ (نافذة جديدة)', () {
      final merged = CircularTimerLogic.reconcileRemaining(
        server: server,
        local: localTight,
        sameDutyEpisode: false,
      );
      expect(merged.remaining, const Duration(hours: 14));
    });

    test('⚠️ لا يمكن للقاعدة أن تمنح وقتاً إضافياً أبداً', () {
      // فحص شامل: مهما كانت القيم، النتيجة ≤ كل من الطرفين.
      for (final s in [Duration.zero, const Duration(hours: 1), const Duration(hours: 14)]) {
        for (final l in [Duration.zero, const Duration(hours: 3), const Duration(hours: 11)]) {
          final merged = CircularTimerLogic.reconcileRemaining(
            server: RemainingCircle(remaining: s, label: '', progress: 0),
            local: RemainingCircle(remaining: l, label: '', progress: 0),
            sameDutyEpisode: true,
          );
          expect(merged.remaining, s <= l ? s : l);
          expect(merged.remaining <= s, isTrue, reason: 'لا زيادة على الخادم');
          expect(merged.remaining <= l, isTrue, reason: 'لا زيادة على المحلي');
        }
      }
    });
  });
}
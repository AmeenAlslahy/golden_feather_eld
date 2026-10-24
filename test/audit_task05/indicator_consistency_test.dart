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

    test('الدائرة تعرض قيمة الخادم كما وردت — لا اشتقاق محلي من المؤشرات', () {
      // مؤشرات توحي بأضيق (استراحة 2:00) لكن دائرة الخادم 3:48:
      // الخادم هو المرجع (قرار المالك) فلا نعيد الاشتقاق محلياً.
      final d = _server().copyWith(
        hosIndicators: _server().hosIndicators.copyWith(
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
      expect(ui.liveRemaining, const Duration(hours: 3, minutes: 48));
    });

    test('مؤشر SHIFT بنمط USED: المتبقّي = 14h ناقص المستخدم', () {
      // 10:12 مستهلك ⇒ المتبقي 3:48، وهو نفسه ما يعرضه الخادم.
      final d = _server();
      expect(const Duration(hours: 14) - d.hosIndicators.shift.value,
          d.remainingCircle.remaining);
    });

    test('مؤشر DRIVING: الدائرة = قيمة الخادم المرساة', () {
      final d = _server().copyWith(
        remainingCircle: const RemainingCircle(
          remaining: Duration(hours: 1),
          label: 'Remaining',
          progress: 0.91,
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

    test('قيمة الخادم السالبة (تجاوز حدّ) تبقى سالبة مع مرور الوقت ولا تُصفَّر', () {
      final ui = CircularTimerLogic.calculateUiState(
        circle: const RemainingCircle(
          remaining: Duration(hours: -1, minutes: -30),
          label: 'Remaining',
          progress: 1,
        ),
        dutyStatus: DutyStatusCode.driving,
        hosIndicators: null,
        statusLabel: 'Driving',
        elapsedSinceSnapshot: const Duration(minutes: 5),
      );
      expect(ui.liveRemaining, const Duration(hours: -1, minutes: -35));
    });
  });

  group('الخادم هو المرجع: استبدال كامل بلا تقليص أحادي', () {
    test('قيمة الخادم تُعرض كاملة حتى لو كانت أكبر من الاشتقاق المحلي', () {
      const serverCircle = RemainingCircle(
        remaining: Duration(hours: 8),
        label: 'Remaining',
        progress: 0,
      );
      // الاشتقاق المحلي القديم كان سيعطي 7:30 (وردية 6:30 مستهلكة).
      const indicators = HosIndicators(
        drive: HosIndicator(
            label: 'DRIVE', value: Duration.zero, type: IndicatorType.used),
        shift: HosIndicator(
            label: 'SHIFT',
            value: Duration(hours: 6, minutes: 30),
            type: IndicatorType.used),
        breakTime: HosIndicator(
            label: 'BREAK',
            value: Duration(hours: 8),
            type: IndicatorType.remaining),
        cycle: HosIndicator(
            label: 'CYCLE', value: Duration.zero, type: IndicatorType.used),
      );
      final ui = CircularTimerLogic.calculateUiState(
        circle: serverCircle,
        dutyStatus: DutyStatusCode.onDutyNotDriving,
        hosIndicators: indicators,
        statusLabel: 'ON_DUTY',
        elapsedSinceSnapshot: Duration.zero,
      );
      expect(ui.liveRemaining, const Duration(hours: 8),
          reason: 'الاستبدال عند كل نبضة جلب (5 دقائق) — لا حارس أحادي');
    });

    test('قيمة أصغر من الخادم تُعرض كما هي (يتقدم الزمن)', () {
      const serverCircle = RemainingCircle(
        remaining: Duration(hours: 3),
        label: 'Remaining',
        progress: 0.8,
      );
      final ui = CircularTimerLogic.calculateUiState(
        circle: serverCircle,
        dutyStatus: DutyStatusCode.onDutyNotDriving,
        hosIndicators: null,
        statusLabel: 'ON_DUTY',
        elapsedSinceSnapshot: Duration.zero,
      );
      expect(ui.liveRemaining, const Duration(hours: 3));
    });

    test('القوس يتقدم مع الوقت — مطابقة الدورة من مؤشرات الخادم', () {
      // الحالة المقيسة حياً: 58 دقيقة متبقية من الدورة (70:00 − 69:02).
      // المطابقة تجد CYCLE فالقوس يزحف من 1 − 58/4200 نحو 1 − 53/4200
      // خلال 5 دقائق — تقدم مرئي بلا أي اشتقاق من النسبة المُدوَّرة.
      const circle = RemainingCircle(
        remaining: Duration(minutes: 58),
        label: 'Remaining',
        progress: 0.99,
      );
      const indicators = HosIndicators(
        drive: HosIndicator(
            label: 'DRIVE', value: Duration.zero, type: IndicatorType.used),
        shift: HosIndicator(
            label: 'SHIFT',
            value: Duration(minutes: 13),
            type: IndicatorType.used),
        breakTime: HosIndicator(
            label: 'BREAK',
            value: Duration(hours: 8),
            type: IndicatorType.remaining),
        cycle: HosIndicator(
            label: 'CYCLE',
            value: Duration(hours: 69, minutes: 2),
            type: IndicatorType.used),
      );
      final ui = CircularTimerLogic.calculateUiState(
        circle: circle,
        dutyStatus: DutyStatusCode.onDutyNotDriving,
        hosIndicators: indicators,
        statusLabel: 'ON_DUTY',
        elapsedSinceSnapshot: const Duration(minutes: 5),
      );
      expect(ui.progress, closeTo(1 - 53 / 4200, 0.0005),
          reason: 'نسبة المستهلك من الدورة 70h بعد 5 دقائق');
      expect(ui.progress, greaterThan(1 - 58 / 4200),
          reason: 'القوس يجب أن يتقدم مع الوقت');
    });

    test('عند p=1.00 لا يُصفَّر القوس (آخر 21 دقيقة من الدورة)', () {
      // العطل المقيس: عند تقريب النسبة إلى 1.00 كان الفرع البديل يحسب
      // إجمالاً = المتبقي، فيقفز القوس من ~99% إلى 0% عند كل نبضة.
      // الآن: مطابقة CYCLE تعطي الحدّ الحقيقي 70h وقوساً ≈ 99.5%.
      const circle = RemainingCircle(
        remaining: Duration(minutes: 21),
        label: 'Remaining',
        progress: 1.0,
      );
      const indicators = HosIndicators(
        drive: HosIndicator(
            label: 'DRIVE', value: Duration.zero, type: IndicatorType.used),
        shift: HosIndicator(
            label: 'SHIFT', value: Duration.zero, type: IndicatorType.used),
        breakTime: HosIndicator(
            label: 'BREAK',
            value: Duration(hours: 8),
            type: IndicatorType.remaining),
        cycle: HosIndicator(
            label: 'CYCLE',
            value: Duration(hours: 69, minutes: 39),
            type: IndicatorType.used),
      );
      final ui = CircularTimerLogic.calculateUiState(
        circle: circle,
        dutyStatus: DutyStatusCode.onDutyNotDriving,
        hosIndicators: indicators,
        statusLabel: 'ON_DUTY',
        elapsedSinceSnapshot: Duration.zero,
      );
      expect(ui.progress, closeTo(1 - 21 / 4200, 0.0005),
          reason: '21 دقيقة من 70 ساعة — يبقى ممتلئاً لا صفراً');
      expect(ui.progress, greaterThan(0.99));
    });

    test('بين النبضات: القوس والرقم يتقدمان معاً كل دقيقة', () {
      const circle = RemainingCircle(
        remaining: Duration(minutes: 58),
        label: 'Remaining',
        progress: 0.99,
      );
      const indicators = HosIndicators(
        drive: HosIndicator(
            label: 'DRIVE', value: Duration.zero, type: IndicatorType.used),
        shift: HosIndicator(
            label: 'SHIFT',
            value: Duration(minutes: 13),
            type: IndicatorType.used),
        breakTime: HosIndicator(
            label: 'BREAK',
            value: Duration(hours: 8),
            type: IndicatorType.remaining),
        cycle: HosIndicator(
            label: 'CYCLE',
            value: Duration(hours: 69, minutes: 2),
            type: IndicatorType.used),
      );
      TimerUiState at(int minutes) => CircularTimerLogic.calculateUiState(
            circle: circle,
            dutyStatus: DutyStatusCode.onDutyNotDriving,
            hosIndicators: indicators,
            statusLabel: 'ON_DUTY',
            elapsedSinceSnapshot: Duration(minutes: minutes),
          );

      final start = at(0);
      final afterOneMinute = at(1);
      final afterFive = at(5);
      expect(start.liveRemaining, const Duration(minutes: 58));
      expect(afterOneMinute.liveRemaining, const Duration(minutes: 57));
      expect(afterFive.liveRemaining, const Duration(minutes: 53));
      expect(afterOneMinute.progress, greaterThan(start.progress),
          reason: 'تقدم كل دقيقة كما في التطبيق المرجعي');
      expect(afterFive.progress, greaterThan(afterOneMinute.progress));
    });

    test('بلا مؤشرات ⇒ قيمة الخادم حرفياً بلا اختراع إجمال', () {
      const circle = RemainingCircle(
        remaining: Duration(minutes: 58),
        label: 'Remaining',
        progress: 0.99,
      );
      final ui = CircularTimerLogic.calculateUiState(
        circle: circle,
        dutyStatus: DutyStatusCode.onDutyNotDriving,
        hosIndicators: null,
        statusLabel: 'ON_DUTY',
        elapsedSinceSnapshot: const Duration(minutes: 5),
      );
      expect(ui.progress, 0.99,
          reason: 'لا مطابقة ممكنة — نعرض نسبة الخادم كما وردت');
    });
  });
}
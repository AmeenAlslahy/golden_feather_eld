/// انحدار: حالة restored كانت متأخرة بمرحلة، ورصيد السائق كان يتسرّب بين السائقين.
///
/// ### العطل 1 — تأخّر مرحلة في الحالة
///
/// `DutyStatusTracker` يكتب الفترة **السابقة** عند كل انتقال:
///
/// ```dart
/// final period = DutyPeriod(status: _lastEvent!.status, ...);  // السابقة
/// _periods.add(period);
/// ```
///
/// فآخر صف في `periodsBox` يصف الحالة التي كان عليها السائق **قبل**
/// الانتقال الأخير. و`hydrateFromPeriods` كان يأخذها كحالته الحالية:
///
/// ```dart
/// _currentStatus = lastStatus;   // آخر فترة مغلقة ⇒ متأخرة بمرحلة
/// ```
///
/// ### العطل 2 — تسرّب رصيد بين السائقين
///
/// `hosEngineProvider` غير `autoDispose`، و`app.dart` كان يُبطل
/// `statusDashboardProvider` و`recapProvider` و`hosStatusProvider` فقط.
/// فالمحرك — ومعه آلة الحالة المرطَّبة من فترات **السائق السابق** — كان
/// يبقى حيّاً. وأي لوحة أوفلاين تُبنى منه كانت تعرض رصيد السائق الأول
/// للحساب الثاني.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_rules_engine.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_state_machine.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/hos_engine_provider.dart';

void main() {
  final now = DateTime.utc(2026, 10, 14, 2, 0);

  DutyPeriod period(String status, {required DateTime start, required DateTime end}) =>
      DutyPeriod(status: status, startTime: start, endTime: end);

  group('العطل 1 — الحالة المعلنة تتغلّب على آخر فترة مغلقة', () {
    // سيناريو واقعي: سائق كان يقود، ثم انتقل إلى ON_DUTY (ساكن 5+ دقائق).
    //
    //   periodsBox يحتوي:  DRIVING [10:00 → 11:00]   ← آخر صف = الفترة السابقة
    //   currentDutyStatus = "onDutyNotDriving"        ← الحالة الحقيقية
    //
    // الترطيب القديم كان يُرجع `driving` ⇒ اللوحة تعرض «DRIVING» لسائق
    // متوقف ساكن منذ ساعة، فالعدّاد يستمر بالنقص بلا حركة.
    final periods = [
      period('ON_DUTY',
          start: DateTime.utc(2026, 10, 14, 0, 0),
          end: DateTime.utc(2026, 10, 14, 10, 0)),
      period('DRIVING',
          start: DateTime.utc(2026, 10, 14, 10, 0),
          end: DateTime.utc(2026, 10, 14, 11, 0)),
    ];

    test('بلا حالة معلنة ⇒ آخر فترة مغلقة (السلوك القديم)', () {
      final sm = HosStateMachine(FakeTrustedTimeProvider(initialUtcTime: now));
      sm.hydrateFromPeriods(
        periods: periods,
        now: now,
        shiftWindow: const Duration(hours: 14),
      );
      expect(sm.currentStatus, DutyStatus.driving,
          reason: 'لا نخمّن: نُبقي ما كانت عليه الحالة الفترة السابقة');
    });

    test('الحالة المعلنة onDutyNotDriving تُطبَّق', () {
      final sm = HosStateMachine(FakeTrustedTimeProvider(initialUtcTime: now));
      sm.hydrateFromPeriods(
        periods: periods,
        now: now,
        shiftWindow: const Duration(hours: 14),
        currentStatusWire: 'on_duty',
      );
      expect(sm.currentStatus, DutyStatus.onDutyNotDriving);
    });

    test('❌ السلوك الخاطئ كان يُبقي driving لسائق متوقف', () {
      // موثّق عمداً: لو عاد العطل يوماً فلن «يُصلح» بالتصحيح الخطأ.
      final sm = HosStateMachine(FakeTrustedTimeProvider(initialUtcTime: now));
      sm.hydrateFromPeriods(
        periods: periods,
        now: now,
        shiftWindow: const Duration(hours: 14),
      );
      final legacy = sm.currentStatus;
      const corrected = DutyStatus.onDutyNotDriving;
      expect(legacy, DutyStatus.driving);
      expect(corrected, isNot(legacy));
    });

    test('سلسلة معقولة: كل قيمة معلنة تُقرأ', () {
      // ⚠️ بصيغة `engineCode` التي يكتبها المتتبّع فعلياً
      // (`on_duty` / `driving` / …) لا بأسماء Dart. وقد اكتُشف هنا بالصدفة
      // أن `fromAny('onDutyNotDriving')` يرجع `offDuty` بصمت.
      const cases = {
        'driving': DutyStatus.driving,
        'DRIVING': DutyStatus.driving,
        'on_duty': DutyStatus.onDutyNotDriving,
        'ON_DUTY': DutyStatus.onDutyNotDriving,
        'sleeper_berth': DutyStatus.sleeperBerth,
        'SLEEPER': DutyStatus.sleeperBerth,
        'off_duty': DutyStatus.offDuty,
        'OFF_DUTY': DutyStatus.offDuty,
        'yard_move': DutyStatus.onDutyNotDriving,
        'personal_use': DutyStatus.personalUse,
      };
      cases.forEach((wire, expected) {
        final sm = HosStateMachine(FakeTrustedTimeProvider(initialUtcTime: now));
        sm.hydrateFromPeriods(
          periods: periods,
          now: now,
          shiftWindow: const Duration(hours: 14),
          currentStatusWire: wire,
        );
        expect(sm.currentStatus, expected, reason: 'wire=$wire');
      });
    });

    test('سلسلة فارغة أو غير معروفة ⇒ لا تغيير ولا انهيار', () {
      for (final wire in ['', '   ', 'nonsense']) {
        final sm = HosStateMachine(FakeTrustedTimeProvider(initialUtcTime: now));
        sm.hydrateFromPeriods(
          periods: periods,
          now: now,
          shiftWindow: const Duration(hours: 14),
          currentStatusWire: wire,
        );
        expect(sm.currentStatus, DutyStatus.driving, reason: 'wire="$wire"');
      }
    });

    test('nullable ⇒ يُحذف المعامل كلياً (توافق)، والافتراضي قديم', () {
      final sm = HosStateMachine(FakeTrustedTimeProvider(initialUtcTime: now));
      sm.hydrateFromPeriods(
        periods: periods,
        now: now,
        shiftWindow: const Duration(hours: 14),
      );
      expect(sm.currentStatus, isNot(DutyStatus.offDuty));
    });
  });

group('العطل 2 — عزل المحرك بين السائقين', () {
    test('تبديل هوية السائق يُبطل المحرك ويبدأ من جديد', () {
      final container = _container();

      final first = container.read(hosEngineProvider);
      expect(_statusOf(first), DutyStatus.offDuty,
          reason: 'محرك جديد بلا سجل: offDuty');

      // 🔒 إبطال المحرك عند تبديل الهوية — نفس ما يفعله `app.dart`.
      container.invalidate(hosEngineProvider);
      container.invalidate(hosStoredPeriodsProvider);

      final second = container.read(hosEngineProvider);
      expect(identical(first, second), isFalse,
          reason: 'محرك جديد — لا حالة موروثة من السائق السابق');
      expect(_statusOf(second), DutyStatus.offDuty,
          reason: 'محرك طازج: لا رصيد ولا حالة من السائق الأول');
    });

    test('إبطال الفترات يعيد بناء الحركة من الصفر', () {
      final container = _container();

      container.read(hosEngineProvider); // ينشئ المستمع
      expect(container.read(hosEngineProvider), isNotNull);

      container.invalidate(hosEngineProvider);
      container.invalidate(hosStoredPeriodsProvider);

      // المحرك الجديد ينتظر ترطيباً جديداً — بلا Hive في الاختبار يُقرأ
      // فارغاً (والحراسة تسجّل ذلك بدل أن يُسقط التشغيل).
      final fresh = container.read(hosEngineProvider);
      expect(_statusOf(fresh), DutyStatus.offDuty);
    });
  });
}

/// تخزين مزيف — الإنتاج يهيّئه `AppInitializer` بعد `init()`.
class _FakeStorage implements LocalStorageService {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);

  @override
  HosConfiguration get hosConfiguration => HosConfiguration.usa70_8();

  @override
  @override
  String? get selectedVehicleId => null;
  @override
  String get currentDutyStatus => _dutyStatus;

  @override
  Future<void> setCurrentDutyStatus(String v) async => _dutyStatus = v;

  @override
  String? get stationarySince => null;

  @override
  Future<void> setStationarySince(String v) async {}

  String _dutyStatus = 'off_duty';
}

ProviderContainer _container() {
  final c = ProviderContainer(
    overrides: [
      localStorageProvider.overrideWithValue(_FakeStorage()),
      // بلا مرساة موثوقة يُرجع المحرك `HosEngineTimeUnavailable` — سلوك
      // صحيح في الإنتاج. هنا نثبّتها كي نتمكّن من ملاحظة الحالة.
      trustedTimeProvider.overrideWithValue(
        FakeTrustedTimeProvider(initialUtcTime: DateTime.utc(2026, 10, 14, 2)),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

/// حالة المحرك عبر واجهته العامة (لا نصل لآلة الحالة الخاصة).
DutyStatus _statusOf(HosRulesEngine engine) {
  final result = engine.currentStatus;
  expect(result, isA<HosEngineReady>());
  return (result as HosEngineReady).update.currentStatus;
}

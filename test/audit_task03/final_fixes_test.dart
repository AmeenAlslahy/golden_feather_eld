// TASK 02/03 — Regression tests for the FINAL round of fixes:
//   (A) session-scoped cache clearing   — cross-driver leak
//   (B) trusted-clock countdown (F-01)  — device-clock manipulation
//   (C) 30-minute break model (F-07)    — 49 CFR 395.3(a)(3)(ii)
//
// Run: flutter test test/audit_task03/
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_calculator.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_rules_engine.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_state_machine.dart';
import 'package:golden_feather_eld/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart';
import 'package:golden_feather_eld/features/vehicle/data/datasources/vehicle_local_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // SharedPreferencesWithCache is built on SharedPreferencesAsync.
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({});
  });

  // =========================================================================
  // (C) F-07 — 30-minute break model
  // =========================================================================
  group('F-07 fixed — breakRequired clears after a qualifying break', () {
    test('after 9h driving the break IS required', () {
      final time = _clock();
      final engine = _engine(time);

      engine.manualTransition(DutyStatus.driving);
      time.advance(const Duration(hours: 9));

      // ignore: avoid_print
      print('BREAK_T0_REQUIRED=${_update(engine).breakRequired}');
      expect(_update(engine).breakRequired, isTrue);
    });

    test('a qualifying 45-minute break CLEARS it', () {
      final time = _clock();
      final engine = _engine(time);

      engine.manualTransition(DutyStatus.driving);
      time.advance(const Duration(hours: 9));
      expect(_update(engine).breakRequired, isTrue);

      engine.manualTransition(DutyStatus.offDuty);
      time.advance(const Duration(minutes: 45));
      engine.manualTransition(DutyStatus.driving);

      // ignore: avoid_print
      print('BREAK_T1_REQUIRED=${_update(engine).breakRequired}');
      expect(_update(engine).breakRequired, isFalse,
          reason: '49 CFR 395.3(a)(3)(ii): the 8h clock restarts after a '
              'qualifying 30-minute interruption');
    });

    test('a SHORT 20-minute stop does NOT clear it', () {
      final time = _clock();
      final engine = _engine(time);

      engine.manualTransition(DutyStatus.driving);
      time.advance(const Duration(hours: 9));
      engine.manualTransition(DutyStatus.offDuty);
      time.advance(const Duration(minutes: 20)); // below the 30-minute minimum
      engine.manualTransition(DutyStatus.driving);

      // ignore: avoid_print
      print('BREAK_SHORT_REQUIRED=${_update(engine).breakRequired}');
      expect(_update(engine).breakRequired, isTrue);
    });

    test('SLEEPER BERTH also counts as a qualifying interruption', () {
      final time = _clock();
      final engine = _engine(time);

      engine.manualTransition(DutyStatus.driving);
      time.advance(const Duration(hours: 9));
      engine.manualTransition(DutyStatus.sleeperBerth);
      time.advance(const Duration(minutes: 40));
      engine.manualTransition(DutyStatus.driving);

      // ignore: avoid_print
      print('BREAK_SLEEPER_REQUIRED=${_update(engine).breakRequired}');
      expect(_update(engine).breakRequired, isFalse,
          reason: 'the CFR allows off-duty, sleeper berth, or a combination');
    });

    test('ON DUTY NOT DRIVING also counts', () {
      final time = _clock();
      final engine = _engine(time);

      engine.manualTransition(DutyStatus.driving);
      time.advance(const Duration(hours: 9));
      engine.manualTransition(DutyStatus.onDutyNotDriving);
      time.advance(const Duration(minutes: 35));
      engine.manualTransition(DutyStatus.driving);

      // ignore: avoid_print
      print('BREAK_ONDUTY_REQUIRED=${_update(engine).breakRequired}');
      expect(_update(engine).breakRequired, isFalse);
    });
  });

  // =========================================================================
  // (C cont.) hydration reconstructs the break counter too
  // =========================================================================
  group('F-07 hydration', () {
    test('a qualifying break in the persisted periods clears the counter', () {
      final time = FakeTrustedTimeProvider(
          initialUtcTime: DateTime.utc(2026, 3, 2, 12));
      final sm = HosStateMachine(time);
      final base = DateTime.utc(2026, 3, 2, 4);

      sm.hydrateFromPeriods(
        periods: [
          DutyPeriod(
              status: 'driving',
              startTime: base,
              endTime: base.add(const Duration(hours: 9))),
          DutyPeriod(
              status: 'off_duty',
              startTime: base.add(const Duration(hours: 9)),
              endTime: base.add(const Duration(hours: 9, minutes: 45))),
          DutyPeriod(
              status: 'driving',
              startTime: base.add(const Duration(hours: 9, minutes: 45)),
              endTime: base.add(const Duration(hours: 10))),
        ],
        now: DateTime.utc(2026, 3, 2, 12),
        shiftWindow: const Duration(hours: 14),
      );

      final engine = HosRulesEngine(
        calculator: HosCalculator(HosConfiguration.usa70_8(), time),
        stateMachine: sm,
        timeProvider: time,
      );
      final update = (engine.currentStatus as HosEngineReady).update;

      // ignore: avoid_print
      print('HYDRATED_BREAK_REQUIRED=${update.breakRequired}');
      expect(update.breakRequired, isFalse,
          reason: 'the 45-min break in the record must reset the 8h clock');
    });
  });

  // =========================================================================
  // (A) session-scoped cache clearing — cross-driver leak
  // =========================================================================
  group('A — cross-driver cache isolation', () {
    test('every offline cache key is in the PreferencesFilter allowList',
        () async {
      // ⚠️ REGRESSION GUARD.
      // SharedPreferencesWithCache يرفض أي مفتاح غير مُدرج بـArgumentError.
      // عندها يفشل الحفظ **بصمت** (داخل try/catch) وتعمل الشاشة بأوفلاين
      // على قيم فارغة — أي عودة كاملة للعطل المُصلَح. هذا الاختبار existed
      // لأن الفشلظهر أولاً عند تشغيل الاختبار لا في المراجعة.
      final storage = await _storage();
      const keys = [
        'hos_dashboard_snapshot',
        'hos_recap_snapshot',
        'vehicle_list_cache',
      ];
      for (final k in keys) {
        await storage.prefs.setString(k, '{"probe":1}');
        // ignore: avoid_print
        print('ALLOWLIST_$k=${storage.prefs.getString(k)}');
        expect(storage.prefs.getString(k), isNotNull,
            reason: '"$k" must be in LocalStorageService allowList or the '
                'offline cache silently never persists');
      }
    });

    test('vehicle cache round-trips through prefs and clears on demand',
        () async {
      final cache = PrefsVehicleLocalCache(await _storage());

      await cache.save({'vehicles': [{'id': '42'}]});
      final loaded = cache.load();
      // ignore: avoid_print
      print('PREFS_ROUNDTRIP=$loaded');
      expect(loaded, isNotNull);
      expect((loaded!['vehicles'] as List).length, 1);

      // GoldenFeatherApp clears this on a session-identity change.
      await cache.clear();
      // ignore: avoid_print
      print('PREFS_AFTER_CLEAR=${cache.load()}');
      expect(cache.load(), isNull,
          reason: "driver A's vehicles must not survive into driver B");
    });
  });

  // =========================================================================
  // (B) F-01 — the countdown runs on one clock
  // =========================================================================
  group('F-01 fixed — countdown uses the trusted clock', () {
    testWidgets('the widget counts down from the TRUSTED clock', (tester) async {
      final trusted = FakeTrustedTimeProvider(
          initialUtcTime: DateTime.utc(2026, 3, 1, 8));
      final stamp = (trusted.currentTime as TrustedTimeAvailable).utc;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [trustedTimeProvider.overrideWithValue(trusted)],
          child: MaterialApp(
            home: Scaffold(
              body: _CountdownHost(stamp: stamp),
            ),
          ),
        ),
      );
      await tester.pump();
      final before = _countdown(tester);
      // ignore: avoid_print
      print('WIDGET_BEFORE=$before');

      // Real elapsed time on the trusted clock, then let the 1s ticker fire.
      trusted.advance(const Duration(minutes: 30));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final after = _countdown(tester);
      // ignore: avoid_print
      print('WIDGET_AFTER=$after');

      // 5:00 at T0, then 5:00 - 0:30 = 04:30.
      expect(before, '05:00');
      expect(after, '04:30',
          reason: 'both ends of the subtraction use TrustedTimeProvider');
    });

    testWidgets('with no trusted anchor the widget still renders', (tester) async {
      // Unanchored provider: the widget must fall back, not crash.
      final trusted = FakeTrustedTimeProvider(); // uninitialized
      final stamp = DateTime.now().subtract(const Duration(minutes: 5));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [trustedTimeProvider.overrideWithValue(trusted)],
          child: MaterialApp(
            home: Scaffold(body: _CountdownHost(stamp: stamp)),
          ),
        ),
      );
      await tester.pump();
      // ignore: avoid_print
      print('WIDGET_UNANCHORED=${_countdown(tester)}');
      expect(_countdown(tester), isNotNull,
          reason: 'must degrade to the wall clock, never crash');
    });
  });
}

// =============================================================================
// Helpers
// =============================================================================

FakeTrustedTimeProvider _clock() => FakeTrustedTimeProvider(
      initialUtcTime: DateTime.utc(2026, 3, 1, 8),
    );

HosRulesEngine _engine(TrustedTimeProvider time) => HosRulesEngine(
      calculator: HosCalculator(HosConfiguration.usa70_8(), time),
      stateMachine: HosStateMachine(time),
      timeProvider: time,
    );

HosStatusUpdate _update(HosRulesEngine engine) =>
    (engine.currentStatus as HosEngineReady).update;

Future<LocalStorageService> _storage() async {
  final s = LocalStorageService();
  await s.init();
  return s;
}

String? _countdown(WidgetTester tester) {
  for (final t in tester.widgetList<Text>(find.byType(Text))) {
    final d = t.data;
    if (d != null && RegExp(r'^-?\d{2}:\d{2}$').hasMatch(d)) return d;
  }
  return null;
}

/// Renders the REAL production MainCircularTimer.
class _CountdownHost extends StatelessWidget {
  const _CountdownHost({required this.stamp});
  final DateTime stamp;

  @override
  Widget build(BuildContext context) {
    return MainCircularTimer(
      circle: const RemainingCircle(
        remaining: Duration(hours: 5),
        label: 'Remaining',
        progress: 0.5,
      ),
      statusLabel: 'Driving',
      dutyStatus: DutyStatusCode.driving,
      snapshotTimestamp: stamp,
    );
  }
}
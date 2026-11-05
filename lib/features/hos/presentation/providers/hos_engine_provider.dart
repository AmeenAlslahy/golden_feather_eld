import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/hos_configuration.dart';
import '../../../../core/domain/entities/hos_models.dart';
import '../../../../core/time/trusted_time_provider.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/events/eld_events_provider.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../sync/data/providers/sync_providers.dart';
import '../../data/providers/duty_period_store_providers.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import '../../domain/engine/hos_state_machine.dart';
import '../../domain/engine/hos_rules_engine.dart';
import '../../domain/engine/hos_calculator.dart';
import '../../domain/engine/tracking/duty_status_tracker.dart';

/// Configuration Provider
final hosConfigurationProvider = Provider<HosConfiguration>((ref) {
  final storage = ref.watch(localStorageProvider);
  return storage.hosConfiguration;
});

/// فترات الخدمة المحفوظة محلياً (Hive periodsBox).
///
/// نافذة عشرة أيام أطول من أن تُغطّى بإعادة تشغيل واحدة، فال periods
/// تكتبها `DutyStatusTracker` عند كل تغيّر حالة. جهاز جديد ⇒ قائمة فارغة.
///
/// ⚠️ قبل هذا لم تكن تُقرأ **أبداً** في هذا المسار: كان المحرك يبدأ من
/// الصفر عند كل إقلاع فلا يعرف أن السائق قضى ساعات قيادة — وهو ما يمنع
/// «العمل أوفلاين كالأونلاين» بعد إعادة التشغيل.
final hosStoredPeriodsProvider = FutureProvider<List<DutyPeriod>>((ref) async {
  final trusted = ref.read(trustedTimeProvider).currentTime;
  final now = trusted is TrustedTimeAvailable
      ? trusted.utc
      : DateTime.now().toUtc();
  final store = ref.watch(dutyPeriodStoreProvider);
  try {
    // القراءة كانت تسلسلية: عشرة أيام × رحلة قرص = تأخير ترطيب مضاعف
    // بلا سبب. الأيام مستقلة، فنجلبها بالتوازي ونحافظ على ترتيبها.
    final days = List<DateTime>.generate(
      10,
      (back) => now.subtract(Duration(days: back)),
      growable: false,
    );
    final chunks = await Future.wait(days.map(store.getPeriods));
    return chunks.expand((chunk) => chunk).toList(growable: false);
  } catch (e) {
    // الفشل هنا لا يمنع التشغيل: نكمل بمحرك فارغ كما كان سابقاً.
    AppLogger.warning('HOS hydration read skipped: $e');
    return const <DutyPeriod>[];
  }
});

/// State Machine & Engine Provider
final hosEngineProvider = Provider<HosRulesEngine>((ref) {
  final config = ref.watch(hosConfigurationProvider);
  final timeProvider = ref.watch(trustedTimeProvider);
  final calculator = HosCalculator(config, timeProvider);
  final stateMachine = HosStateMachine(
    timeProvider,
    breakDuration: Duration(minutes: config.breakDurationMinutes),
  );

  // ♻️ استعادة حالة HOS من فترات الخدمة المحفوظة محلياً.
  //
  // الترطيب غير متزامن فنستمع لا نستدعي. ولا نحتاج إبطال أي مزوّد بعد
  // وصول الفترات: `HosRulesEngine.currentStatus` يعيد الحساب من آلة
  // الحالة في **كل** قراءة (`_buildStatusUpdate`)، فكل قارئ تالٍ يرى
  // الحالة المستعادة بلا إعادة بناء.
  ref.listen(hosStoredPeriodsProvider, (_, next) {
    final periods = next.valueOrNull;
    if (periods == null || periods.isEmpty) return;
    final trusted = timeProvider.currentTime;
    final now = trusted is TrustedTimeAvailable
        ? trusted.utc
        : DateTime.now().toUtc();
    stateMachine.hydrateFromPeriods(
      periods: periods,
      now: now,
      shiftWindow: Duration(minutes: config.shiftLimitMinutes),
      cycleWindow: const Duration(days: 8),
      // الحالة المعلنة، لا حالة آخر فترة مغلقة (متأخرة بمرحلة).
      currentStatusWire: _declaredStatus(ref),
    );
  });

  ref.onDispose(() {
    stateMachine.dispose();
  });

  return HosRulesEngine(
    calculator: calculator,
    stateMachine: stateMachine,
    timeProvider: timeProvider,
  );
});

/// الحالة المعلنة مخزَّنة في التفضيلات.
///
/// 🔒 القراءة محاطة بـ try/catch عمداً: [LocalStorageService] قد لا
/// تكون مهيَّأة بعد (إقلاع مبكر، خطأ تهيئة). وفشل قراءتها يجب ألا
/// يُسقط محرك HOS كله — نكمل بسلوك آخر فترة مغلقة.
String? _declaredStatus(Ref ref) {
  try {
    return ref.read(localStorageProvider).currentDutyStatus;
  } catch (e) {
    AppLogger.warning('HOS hydration: declared status unavailable: $e');
    return null;
  }
}

/// جهوزية ترطيب المحرك.
/// 🔴 كان هذا **غير معلن**، فكان بناء اللوحة أوفلاين يقرأ المحرك قبل
/// اكتمال القراءة من القرص — سباقٌ صامت يعرض رصيداً كاملاً (11:00) ثم
/// يهبط إلى ما ي真相 بعد ثوانٍ، بلا أي إعادة بناء ولا إشعار.
///
/// يجب **انتظاره** قبل بناء أي لوحة من المحرك.
final hosHydrationReadyProvider = FutureProvider<void>((ref) async {
  // ضمان إنشاء المحرك (وبالتالي المستمع) أولاً.
  ref.watch(hosEngineProvider);
  // نفس الكاش المخزَّن مؤقتاً ⇒ لا قراءة ثانية من القرص.
  await ref.watch(hosStoredPeriodsProvider.future);

  // P1.3 — لا تُعرض لوحة مبنية على حالة جزئية بينما سجل الأحداث الدائم
  // ما زال يُستعاد. السائق قد يكون تغيّر أثناء الإقلاع، فنعيد المحاولة
  // كلما عرفت الجلسة هويته.
  final driverId = ref.watch(currentDriverIdProvider);
  if (driverId == null || driverId <= 0) return;
  final tracker = ref.read(dutyStatusTrackerProvider);
  await tracker.hydrateForDriver(driverId);
  if (!tracker.isHydrated) {
    throw StateError('Duty journal hydration failed');
  }
});

/// Duty Status Tracker Provider
final dutyStatusTrackerProvider = Provider<DutyStatusTracker>((ref) {
  final periodStore = ref.watch(dutyPeriodStoreProvider);
  final localStorage = ref.watch(localStorageProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  final dashboardBackend = ref.watch(statusDashboardBackendProvider);
  final timeProvider = ref.watch(trustedTimeProvider);

  final tracker = DutyStatusTracker(
    dutyPeriodStore: periodStore,
    localStorage: localStorage,
    syncEngine: syncEngine,
    dashboardBackend: dashboardBackend,
    timeProvider: timeProvider,
    readDriverId: () => ref.read(currentDriverIdProvider),
    journal: ref.watch(dutyEventJournalProvider),
    // لا نقرأ مزوّداً آخر داخل باني المتتبع: القراءة تُنعش المزوّد وتُطلق
    // مستمعيه أثناء بناء هذا المزوّد (تحذير Riverpod القاتل). نؤجّل البدء
    // إلى ما بعد البناء.
    hydrateOnCreate: false,
  );

  // P1.1 — rebuild the open segment from journal evidence as soon as the
  // driver identity is known. The stored owner is used for replay, not the
  // current session.
  void hydrate(int? driverId) {
    if (driverId == null || driverId <= 0) return;
    unawaited(tracker.hydrateForDriver(driverId));
  }

  var disposed = false;
  ref.onDispose(() => disposed = true);

  // الترطيب الأول بعد اكتمال البناء. `hosHydrationReadyProvider` ينتظر
  // `hydrateForDriver` نفسها، فهذه مجرد بداية مبكّرة غير حاجزة.
  Future<void>.microtask(() {
    if (disposed) return;
    hydrate(ref.read(currentDriverIdProvider));
  });
  ref.listen<int?>(currentDriverIdProvider, (_, next) => hydrate(next));

  ref.listen<AsyncValue>(eldEventsStreamProvider, (_, next) {
    if (next.hasValue && next.value != null) {
      tracker.processEldEvent(next.value!);
    }
  });

  ref.onDispose(() {
    tracker.dispose();
  });

  return tracker;
});

/// سرعة المركبة الحالية كم/س — 0 عند غياب القياس.
final currentSpeedKmhProvider = Provider<double>((ref) {
  final speedMs = ref.watch(currentVehicleSpeedProvider);
  return (speedMs ?? 0) * 3.6;
});

/// هل المركبة متحركة الآن (السرعة ≥ عتبة الحركة من الإعداد)؟
/// كان المنطق مكرراً في change_status_page وHosNotifier.changeStatus —
/// هذا هو المصدر الوحيد للقرار.
final isVehicleMovingProvider = Provider<bool>((ref) {
  return ref.watch(currentSpeedKmhProvider) >=
      ref.watch(hosConfigurationProvider).movingSpeedThresholdKmh;
});

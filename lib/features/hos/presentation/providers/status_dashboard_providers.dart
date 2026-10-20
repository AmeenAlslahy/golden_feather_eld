import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/time/trusted_time_provider.dart';
import '../../../../domain/duty_status/duty_status_code.dart';
import '../../../../domain/duty_status/status_dashboard.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../data/providers/status_dashboard_repository_providers.dart';
import '../../domain/engine/hos_rules_engine.dart';
import '../../domain/engine/hos_offline_dashboard.dart';
import '../../domain/usecases/get_status_dashboard_use_case.dart';
import 'hos_provider.dart';
import 'hos_engine_provider.dart';
import '../../../../core/events/app_events.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../core/error/failure.dart';

/// مطابقة حالة المحرك المحلية مع رمز اللوحة — تُستخدم لتخطي إعادة الجلب
/// عندما تكون اللوحة محدثة أصلاً (مثلاً من استجابة POST تغيير الحالة).
DutyStatusCode _engineStatusCode(DutyStatus status) {
  switch (status) {
    case DutyStatus.driving:
      return DutyStatusCode.driving;
    case DutyStatus.onDutyNotDriving:
      return DutyStatusCode.onDutyNotDriving;
    case DutyStatus.sleeperBerth:
      return DutyStatusCode.sleeperBerth;
    case DutyStatus.offDuty:
      return DutyStatusCode.offDuty;
    case DutyStatus.personalUse:
      return DutyStatusCode.personalConveyance;
  }
}

// --- Clean Architecture Providers ---

final getStatusDashboardUseCaseProvider = Provider<GetStatusDashboardUseCase>((
  ref,
) {
  return GetStatusDashboardUseCase(
    ref.watch(statusDashboardRepositoryProvider),
  );
});
// Use cases mapped to providers

// --- State Providers ---

/// Manages the status dashboard state.
///
/// **Lifecycle:**
/// - Loads initial dashboard on first watch.
/// - Rebuilds when [getStatusDashboardUseCaseProvider] changes.
/// - Mutations via [changeStatus] update state in place.
/// - Refreshes reactively on duty status transitions or log data events.
///
/// **Error handling:**
/// - Errors are surfaced as [AsyncError] with the underlying [Failure].
final statusDashboardProvider =
    AsyncNotifierProvider<StatusDashboardNotifier, StatusDashboard>(
      StatusDashboardNotifier.new,
    );

/// الطابع الزمني لآخر لقطة لوحة — على **الساعة الموثوقة** (خادم مُثبَّت).
///
/// ⚠️ كان `DateTime.now()` (ساعة الجهاز). لأن `MainCircularTimer` يحسب
/// `liveRemaining = serverRemaining − (trustedNow − snapshotStamp)`، فإن
/// ختم اللقطة بساعة الجهاز يجعل الطرح بين ساعتين غير مرتبطتين ويسمح
/// للسائق بتجميد أو تعجيل العدّاد القانوني بتعديل ساعة جهازه.
///
/// نستعمل الساعة الموثوقة إن توفّرت، وإلا ساعة الجهاز كبديل متحفّظ.
final statusDashboardSnapshotTimestampProvider = StateProvider<DateTime>(
  (ref) => _trustedStampOrFallback(ref),
);

DateTime _trustedStampOrFallback(Ref ref) {
  final trusted = ref.read(trustedTimeProvider).currentTime;
  if (trusted is TrustedTimeAvailable) return trusted.utc;
  return DateTime.now();
}

/// ختم اللوحة بلحظة قياسها الحقيقية.
///
/// [repositorySnapshotAt] هي لحظة القياس التي سجّلها المستودع:
/// - لقطة محفوظة من القرص ⇒ لحظةَ قياسها الأصلية، **لا** "الآن".
///   هذا هو الفرق بين عدّاد صادق وآخر يسامح السائق بمدة إغلاق التطبيق.
/// - استجابة حيّة ⇒ `null` يُختم بلحظة الاستلام (وهو الصحيح).
DateTime _stampFor(Ref ref, DateTime? repositorySnapshotAt) =>
    repositorySnapshotAt ?? _trustedStampOrFallback(ref);

class StatusDashboardNotifier extends AsyncNotifier<StatusDashboard> {
  /// تذكرة تكرار الطلبات.
  ///
  /// بدونها كان استجابة GET قديمة تكتب فوق نتيجة POST أحدث (F-03):
  /// التطبيق يحدّث الدائرة من استجابة تغيير الحالة ثم تصل نتيجة بحث
  /// متأخرة فتمسحها وتُرجِع رقماً أقدم — فيومض الوقت للسائق.
  int _requestSeq = 0;

  @override
  Future<StatusDashboard> build() async {
    // تحديث تفاعلي تلقائي للوحة عند تغير حالة السائق في محرك HOS.
    // تخطي الجلب إن كانت اللوحة تحمل الحالة الجديدة أصلاً (تغذية من
    // استجابة POST) — يوفر رحلة شبكة كاملة بعد كل تغيير.
    ref.listen<HosEngineResult>(hosStatusProvider, (prev, next) {
      if (prev is HosEngineReady && next is HosEngineReady) {
        if (prev.update.currentStatus != next.update.currentStatus) {
          final current = state.valueOrNull;
          if (current != null) {
            final engineCode = _engineStatusCode(next.update.currentStatus);
            if (current.currentDutyStatus == engineCode) {
              return;
            }
            // لتجنب تحديث الشبكة المتأخر: الـ Yard Move يُعتبر OnDutyNotDriving في المحرك
            if (engineCode == DutyStatusCode.onDutyNotDriving &&
                current.currentDutyStatus == DutyStatusCode.yardMove) {
              return;
            }
          }
          refresh();
        }
      }
    });

    final bus = ref.watch(appEventBusProvider);
    final sub = bus.stream.listen((event) {
      if (event == AppEvent.logDataChanged) refresh();
    });
    ref.onDispose(sub.cancel);

    // P0 leak fix: بلا هوية مثبتة ومستقرة لا يبدأ أي GET (يمنع قراءات
    // نافذة logout والتكتكة بعدها). يُرمى SessionMissing لا NetworkFailure
    // حتى لا يُقرأ كعطل شبكة.
    final auth = ref.read(authStateProvider);
    if (auth.user == null || auth.transitioning) {
      throw const SessionMissingFailure();
    }

    _disposed = false;
    ref.onDispose(() => _disposed = true);

    // P2 — كاش-أولاً: لقطة القرص تُعرض فوراً بختم لحظة قياسها الأصلية
    // (عدّاد صادق لا "الآن")، ويُجدَّد من الخادم في الخلفية فور انتهاء
    // البناء — بدل حجب الشاشة حتى ~37 ثانية (مهلة + إعيدات) ثم الرجوع
    // إلى نفس الكاش على أي حال.
    final repo = ref.read(statusDashboardRepositoryProvider);
    final cached = repo.cachedDashboard;
    if (cached != null) {
      _scheduleBackgroundReconcile(repo.snapshotAt);
      return cached;
    }

    final useCase = ref.watch(getStatusDashboardUseCaseProvider);
    final mySeq = ++_requestSeq;
    final result = await useCase.execute();

    // ⚠️ فرع الفشل خارج `fold`: بناء اللوحة المحلية `async` (ينتظر
    // الترطيب)، و`fold` لا يقبل closures غير متزامنة.
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      // بلا خادم وبلا لقطة محفوظة: نبني لوحة **حقيقية** من المحرك
      // المحلي المستعاد من سجل الخدمة، بدل عرض أرقام مُختلَقة —
      // **أوفلاين فقط**: عبر الإنترنت لا تُستخدم بيانات محلية إطلاقاً
      // (قرار المالك: الخادم هو المرجع)، والفشل يُعرض بصدق مع إعادة محاولة.
      final local = ref.read(networkInfoProvider).isConnected
          ? null
          : await _buildOfflineDashboardFromEngine();
      if (local != null) {
        ref.read(statusDashboardSnapshotTimestampProvider.notifier).state =
            _stampFor(ref, null);
        return local;
      }
      throw failure;
    }

    final dashboard = result.getRight().toNullable()!;
    if (mySeq != _requestSeq) {
      // وصل رد أقدم بعد أحدث — نُهمله ونعيد ما هو معروض حالياً.
      return state.valueOrNull ?? dashboard;
    }
    // 🔴 لحظة القياس من المستودع، لا "الآن".
    // لقطة نستُرجعها من القرص تحمل لحظة قياسها الأصلية؛ ختمها بالآن
    // يُلغي مدة إغلاق التطبيق كاملة من العدّاد — رصيد قانوني بلا سند.
    ref.read(statusDashboardSnapshotTimestampProvider.notifier).state =
        _stampFor(ref, ref.read(statusDashboardRepositoryProvider).snapshotAt);
    return dashboard;
  }

  /// نبني لوحة من المحرك المحلي عند غياب بيانات الخادم.
  ///
  /// يعيد null عند أي تعذّر (وقت غير موثوق، أو فشل تهيئة أحد
  /// الاعتماديات) — عندها نُبقي الفشل الأصلي ليعرض المستخدم رسالة
  /// "غير متاح" بدل أرقام ملفّقة.
  ///
  /// 🔴 **ينتظر اكتمال الترطيب** ([hosHydrationReadyProvider]).
  ///
  /// الترطيب يقرأ الفترات من القرص بشكل غير متزامن. وقبل هذا الانتظار
  /// كان البناء يقرأ المحرك فوراً، فيبني اللوحة من محرك **لم يُرطَّب بعد**
  /// — أي 11:00 / 14:00 / 8:00 كاملة، ثم يهبط العدّاد إلى ما ي真相 بعد
  /// ثوانٍ بلا إعادة بناء. السائق يرى ارتداداً في رقمه القانوني.
  ///
  /// ملاحظة: القراءة محاطة بـ try/catch عمداً. المسار يُنفَّذ أثناء
  /// بناء المزوّد نفسه؛ أي استثناء هنا كان سيُسقط اللوحة كاملة
  /// بدلاً من الرجوع للخطأ الأصلي.
  Future<StatusDashboard?> _buildOfflineDashboardFromEngine() async {
    try {
      // مهلة قصيرة: الانتظار لا يجوز أن يعلّق الشاشة على قرص بطيء.
      await ref
          .read(hosHydrationReadyProvider.future)
          .timeout(const Duration(seconds: 3), onTimeout: () {});
    } catch (_) {
      // تعذّر الترطيب ⇒ نكمل؛ البناء التالي يجرّب من جديد.
    }

    try {
      final engine = ref.read(hosEngineProvider);
      final result = engine.currentStatus;
      if (result is! HosEngineReady) return null;

      final driverId = ref.read(currentDriverIdProvider);
      return const HosOfflineDashboardBuilder().build(
        engineResult: result,
        driverId: DriverId(driverId ?? 0),
        driverName: ref.read(authStateProvider).user?.fullName ?? '',
        driverDisplayText: ref.read(authStateProvider).user?.fullName ?? '',
      );
    } catch (e) {
      // ignore: avoid_print
      print('offline dashboard build skipped: $e');
      return null;
    }
  }

  /// تغذية اللوحة مباشرة من استجابة POST تغيير الحالة — بلا شبكة.
  /// تُستخدم بعد قبول الخادم لتظهر الدائرة الجديدة فوراً.
  void applyServerDashboard(StatusDashboard dashboard) {
    // POST هو الأحدث دائماً: أي GET جارٍ يجب أن يُتجاهل عند وصوله.
    ++_requestSeq;
    final stamp = _stampFor(ref, null);
    ref.read(statusDashboardSnapshotTimestampProvider.notifier).state = stamp;
    try {
      ref
          .read(statusDashboardRepositoryProvider)
          .cacheDashboard(dashboard, takenAt: stamp);
    } catch (_) {}
    state = AsyncValue.data(dashboard);
  }

  /// Manually reloads the dashboard.
  Future<void> refresh({bool showLoading = true}) async {
    // P0 leak fix: نبضات المؤقت بعد logout (وغيرها بلا جلسة) صامتة تماماً:
    // لا HTTP ولا مساس بالحالة — فلا يتحول الرفض لخطأ في جلسة جديدة.
    // NOTE: ref.read داخل AsyncNotifier مسموح (قراءة لمرة واحدة لا اشتراك).
    final auth = ref.read(authStateProvider);
    if (auth.user == null || auth.transitioning) return;

    if (showLoading && !state.hasValue) {
      state = const AsyncValue<StatusDashboard>.loading();
    }

    final mySeq = ++_requestSeq;
    final useCase = ref.read(getStatusDashboardUseCaseProvider);
    final result = await useCase.execute();

    // كما في `build`: فرع الفشل خارج `fold` لأن بناء اللوحة `async`.
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      // ⚠️ لا نمسح اللوحة الحالية عند فشل التحديث.
      if (!state.hasValue) {
        final connected = ref.read(networkInfoProvider).isConnected;
        if (!connected && ref.read(hosHydrationReadyProvider).hasError) {
          // P1.3: a failed journal hydration is cached as a provider error;
          // drop it so this user-initiated retry replays before the build.
          ref.invalidate(hosHydrationReadyProvider);
        }
        final local = connected
            ? null
            : await _buildOfflineDashboardFromEngine();
        if (local != null) {
          // لوحة مبنية من المحرك المحلي الآن ⇒ تُقاس الآن.
          ref.read(statusDashboardSnapshotTimestampProvider.notifier).state =
              _stampFor(ref, null);
          state = AsyncValue.data(local);
          return;
        }
        state = AsyncValue.error(failure, StackTrace.current);
      }
      return;
    }

    final dashboard = result.getRight().toNullable()!;
    if (mySeq != _requestSeq) return;
    // 🔴 الخادم هو المرجع: كل نبضة جلب **تستبدل** اللقطة السابقة كاملة
    // (قرار المالك). بين النبضات يستوفي العرض زمنياً من هذه القيمة
    // المرساة (CircularTimerLogic)، فلا حارس أحادي ولا دمج مؤشرات محلي.
    final stamp = _stampFor(
      ref,
      ref.read(statusDashboardRepositoryProvider).snapshotAt,
    );
    ref.read(statusDashboardSnapshotTimestampProvider.notifier).state = stamp;
    state = AsyncValue.data(dashboard);
  }

  /// Clears any error state and reloads.
  Future<void> clearErrorAndReload() => refresh();

  /// تصحيح دوري من الخادم (كل 5 دقائق، وعند العودة من الخلفية).
  ///
  /// يختلف عن [refresh] في نقطتين مقصودتين:
  ///
  /// 1. **لا يضع شاشة تحميل** ولا يمسح اللوحة المعروضة. نبضة كل 5 دقائق
  ///    تُظهر مؤشر تحميل متقطّعاً أمام السائق بلا سبب.
  /// 2. **لا يلمس الحالة عند الفشل إطلاقاً.** صمتٌ أفضل من وميض خطأ
  ///    على شاشة يعمل عليها السائق.
  ///
  /// كما يحرس ضدّ التراكب: نبضة قد تتأخر (Doze، شبكة بطيئة) فتتراكم
  /// طلبات وتتخمّر الإجابات على الشاشة بلا فائدة.
  Future<void> reconcileWithServer() async {
    final auth = ref.read(authStateProvider);
    if (auth.user == null || auth.transitioning) return;
    if (_reconciling) return;
    _reconciling = true;
    try {
      await refresh(showLoading: false);
    } finally {
      _reconciling = false;
    }
  }

  bool _reconciling = false;

  bool _disposed = false;

  /// P2 — نبضة تصحيح بعد عرض لقطة الكاش مباشرة.
  ///
  /// `Future.delayed(Duration.zero)` (حدث حلقة الأحداث، وليس microtask)
  /// ليكون البناء قد اكتمل وثُبّتت الحالة قبل أول لمسة — فلا يُعدَّل
  /// `state` أثناء البناء (تأكيد Riverpod على المزوّدات أثناء build).
  /// يُختم العدّاد بلحظة قياس اللقطة **قبل** التصحيح ليتنازل العرض من
  /// نقطة صحيحة إن طال النداء. النبضة بلا شاشة تحميل وبلا مسح للحالة
  /// عند الفشل (`reconcileWithServer`)، فأسوأ حالتها إبقاء اللقطة.
  void _scheduleBackgroundReconcile(DateTime? cachedStamp) {
    Future<void>.delayed(Duration.zero, () {
      if (_disposed) return;
      if (cachedStamp != null) {
        ref.read(statusDashboardSnapshotTimestampProvider.notifier).state =
            cachedStamp;
      }
      reconcileWithServer();
    });
  }
}

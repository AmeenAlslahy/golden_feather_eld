import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'dart:async';

import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/session/auth_session_provider.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart'; // ignore_architecture
import '../../../logs/data/datasources/log_local_data_source.dart'; // ignore_architecture
import '../../../logs/data/sync/log_sync_outcome_handler.dart'; // ignore_architecture
import '../../../../core/events/app_events.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/time/time_authority_provider.dart';
import '../../../../core/events/eld_events_provider.dart';
import '../../../../core/domain/entities/connection_status.dart';
import '../../domain/entities/dispatch_auth.dart';
import '../../domain/entities/pending_event.dart';
import '../../domain/repositories/duty_event_journal.dart';
import '../../domain/repositories/offline_queue.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../domain/usecases/sync_engine.dart';
import '../datasources/sync_local_data_source.dart';
import '../repositories/memory_duty_event_journal.dart';
import '../repositories/memory_offline_queue.dart';
import '../repositories/sqlite_duty_event_journal.dart';
import '../repositories/sqlite_offline_queue.dart';
import '../repositories/sync_repository_impl.dart';
import '../repositories/traccar_remote_event_dispatcher.dart';

// --- DI: طبقة البيانات هي من تركّب مستودعها ومحركها (المرحلة 3b) ---

final syncLocalDataSourceProvider = Provider<SyncLocalDataSource>((ref) {
  return SyncLocalDataSourceImpl();
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final localDataSource = ref.watch(syncLocalDataSourceProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  final dispatcher = ref.watch(remoteEventDispatcherProvider);
  return SyncRepositoryImpl(
    localDataSource: localDataSource,
    networkInfo: networkInfo,
    dispatcher: dispatcher,
  );
});

class MockRemoteEventDispatcher implements RemoteEventDispatcher {
  @override
  Future<Either<Failure, bool>> dispatch(PendingEvent event) async {
    // محاكاة إرسال للـ Backend (Traccar أو غيره)
    await Future.delayed(const Duration(milliseconds: 500));
    return const Right(true);
  }
}

class FailClosedRemoteEventDispatcher implements RemoteEventDispatcher {
  @override
  Future<Either<Failure, bool>> dispatch(PendingEvent event) async {
    // حماية (Fail-closed): نمنع فقدان البيانات بحظر الحذف الوهمي في الإنتاج
    return const Left(
      ServerFailure(
        message: 'Production dispatcher not implemented yet. Event retained.',
      ),
    );
  }
}

final offlineQueueProvider = Provider<OfflineQueue>((ref) {
  // ساعة واحدة لكل قرار "جاهز الآن": نفس ساعة `RetryPolicy` في SyncEngine.
  final authority = ref.watch(timeAuthorityProvider);
  if (AppEnvironmentConfig.current == AppEnvironment.mock) {
    return MemoryOfflineQueue(now: authority.nowUtc);
  }
  return SQLiteOfflineQueue(now: authority.nowUtc);
});

/// P1.1 — durable duty-event evidence. Sharing the queue's `Database` is what
/// makes the journal row + queue row a single transaction.
final dutyEventJournalProvider = Provider<DutyEventJournal>((ref) {
  final queue = ref.watch(offlineQueueProvider);
  if (queue is SQLiteOfflineQueue) {
    return SqliteDutyEventJournal(() => queue.database);
  }
  return MemoryDutyEventJournal(queue: queue);
});

/// P0 — ترجمة نتيجة المزامنة إلى حالة مخزّنة + إشارة تحديث الواجهة.
/// يعيش في طبقة البيانات لأنها تملك الكاش والحدث؛ لا منطق عرض فيه.
final logSyncOutcomeHandlerProvider = Provider<LogSyncOutcomeHandler>((ref) {
  return LogSyncOutcomeHandler(
    local: ref.watch(logLocalDataSourceProvider),
    events: ref.watch(appEventBusProvider),
    // تعديلات متعددة لنفس الحدث قد تنتظر؛ التأكيد لا يمسح الشارة إلا بعد
    // مغادرة آخر طلب للطابور.
    queue: ref.watch(offlineQueueProvider),
  );
});

final remoteEventDispatcherProvider = Provider<RemoteEventDispatcher>((ref) {
  final env = AppEnvironmentConfig.current;

  if (env == AppEnvironment.mock) {
    return MockRemoteEventDispatcher();
  }

  final dutyStatusBackend = ref.watch(dutyStatusBackendProvider);
  final dailyLogsBackend = ref.watch(dailyLogsBackendProvider);
  final dvirBackend = ref.watch(dvirBackendProvider);
  final localDataSource = ref.watch(authSessionReaderProvider);
  final inspectionBackend = ref.watch(inspectionBackendProvider);
  final outcomeHandler = ref.watch(logSyncOutcomeHandlerProvider);
  return TraccarRemoteEventDispatcher(
    dutyStatusBackend,
    dailyLogsBackend,
    dvirBackend,
    localDataSource,
    inspectionBackend: inspectionBackend,
    // P0 — مسار تبديل السائق المشارك الأوفلاين (كان يسقط على default).
    // قراءة كسولة (نمط observeAuth/cachedLogOwner): بعض المحولات لا تدعم
    // الجلسات فترمي عند الاشتراك — لا يجوز إسقاط الموزّع كله لأجلها.
    readDriverSessionBackend: () => ref.read(driverSessionBackendProvider),
    // P0 2B-1 — سياق الجلسة للسياج (قراءة لمرة واحدة لكل dispatch،
    // بلا اشتراك). الـ dispatcher نفسه يبقى بلا Ref.
    observeAuth: () async {
      final auth = ref.read(authStateProvider);
      return DispatchAuthContext(
        // P0 2B-1 (مراجعة 2026-10-30) — هوية الإرسال بنفس فضاء الختم
        // (معرّف سائق ELD من currentDriverIdProvider). كان يُقرأ من
        // auth.user.id (مستخدم Traccar — جدول آخر) فيُوقف كل حدث
        // طابور مختوم بمعرّف ELD ولو كانت الجلسة صحيحة.
        driverId: ref.read(currentDriverIdProvider),
        transitioning: auth.transitioning,
      );
    },
    // P0 2B-1 — إثبات RECOVERABLE عبر كاش السجلات (قراءة خالصة).
    cachedLogOwner: (logId) =>
        ref.read(logLocalDataSourceProvider).ownerOfCachedLog(logId),
    // P0 — بعد كل استجابة فعلية: تؤكد الاعتماد فقط عند `isCertified`،
    // وتحدّث النموذج من استجابة الخادم دون افتراض الاكتمال.
    onSettled: outcomeHandler.onVerified,
  );
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final queue = ref.watch(offlineQueueProvider);
  final dispatcher = ref.watch(remoteEventDispatcherProvider);
  final timeAuthority = ref.watch(timeAuthorityProvider);
  final outcomeHandler = ref.watch(logSyncOutcomeHandlerProvider);

  final engine = SyncEngine(
    queue: queue,
    dispatcher: dispatcher,
    timeAuthority: timeAuthority,
    // خروج الطلب نهائياً (رفض/استنفاد محاولات) → SYNC_FAILED بدل
    // PENDING_SYNC، مع إبقاء بيانات المستخدم في الكاش.
    onDeadLettered: outcomeHandler.onDeadLettered,
    // P0 2B-1 — مراجعة المؤجل المؤهل (T3) تحتاج الجلسة الحالية.
    // نفس فضاء الختم: معرّف سائق ELD (مراجعة 2026-10-30).
    observeAuth: () async {
      final auth = ref.read(authStateProvider);
      return DispatchAuthContext(
        driverId: ref.read(currentDriverIdProvider),
        transitioning: auth.transitioning,
      );
    },
  );

  // استماع لحالة الاتصال من نظام التتبع عبر Provider المعماري النظيف
  ref.listen<AsyncValue<ConnectionStatus>>(eldConnectionStatusProvider, (
    _,
    next,
  ) {
    if (next.value == ConnectionStatus.connected) {
      // عند عودة الاتصال، نقوم بمحاولة المزامنة
      engine.triggerSync();
    }
  });

  // SRS 6.8 — also flush the queue when *network* connectivity returns,
  // not only when the vehicle link reconnects.
  final networkSubscription = ref
      .watch(networkInfoProvider)
      .onConnectionChange
      .listen((online) {
        if (online) engine.triggerSync();
      });
  ref.onDispose(() => networkSubscription.cancel());

  // نبضة دورية.
  //
  // السبب: RetryPolicy.puts الأحداث الفاشلة في backoff حتى ٥٠ ثانية
  // كحد أقصى. لو عاد الاتصال بينما كان حدث في نافذة backoff، فإن
  // triggerSync من 이벤��ة ال��ص��لية يخرج فوراً (القائمة الجاهزة فارغة)
  // ولا يوجد ما يوقظه بعد انقضاء النافذة → يبدو التزامن "ميتاً" ريثما
  // يمرّ الوقت، وقد لا يعود الاتصال إطلاقاً.
  //
  // ℹ️ لا يوجد مؤقّت دوري آخر يلتقط هذه الأحداث.
  final heartbeat = Timer.periodic(
    const Duration(seconds: 30),
    (_) => engine.triggerSync(),
  );
  ref.onDispose(() => heartbeat.cancel());

  return engine;
});

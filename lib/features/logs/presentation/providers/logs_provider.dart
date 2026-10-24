import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/entities/daily_form_data.dart';
import '../../domain/repositories/log_repository.dart';
import '../../data/providers/log_repository_providers.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../../../core/events/app_events.dart';

/// حالة شاشة السجلات
class LogsState {
  final List<DailyLog> logs;
  final DailyLog? selectedLog;
  final bool isLoading;
  final String? error;

  /// آخر صفحة جُلبت من الخادم (`page` في الترقيم الموحّد).
  final int page;
  final bool hasReachedMax;
  final String? loadMoreError;

  /// True while the events of [selectedLog] are being fetched.
  final bool isLoadingEvents;

  /// Set when fetching the events of [selectedLog] failed (raw failure
  /// message; sanitize before display).
  final String? eventsError;

  const LogsState({
    this.logs = const [],
    this.selectedLog,
    this.isLoading = false,
    this.error,
    this.page = 0,
    this.hasReachedMax = false,
    this.loadMoreError,
    this.isLoadingEvents = false,
    this.eventsError,
    this.serverForm,
  });

  final DailyFormData? serverForm;

  LogsState copyWith({
    List<DailyLog>? logs,
    DailyLog? selectedLog,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? page,
    bool? hasReachedMax,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    bool? isLoadingEvents,
    String? eventsError,
    bool clearEventsError = false,
    DailyFormData? serverForm,
    bool clearServerForm = false,
  }) {
    return LogsState(
      logs: logs ?? this.logs,
      selectedLog: selectedLog ?? this.selectedLog,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      page: page ?? this.page,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      loadMoreError: clearLoadMoreError
          ? null
          : (loadMoreError ?? this.loadMoreError),
      isLoadingEvents: isLoadingEvents ?? this.isLoadingEvents,
      eventsError: clearEventsError ? null : (eventsError ?? this.eventsError),
      serverForm: clearServerForm ? null : (serverForm ?? this.serverForm),
    );
  }
}

/// مزود السجلات
final logsProvider = StateNotifierProvider.autoDispose<LogsNotifier, LogsState>(
  (ref) {
    final repository = ref.watch(logRepositoryProvider);
    final driverId = ref.watch(currentDriverIdProvider);
    final notifier = LogsNotifier(repository, driverId, ref);

    final sub = ref.read(appEventBusProvider).stream.listen((event) {
      if (event == AppEvent.logDataChanged) {
        notifier.loadLogs(refresh: true);
      }
    });

    ref.onDispose(sub.cancel);

    return notifier;
  },
);

class LogsNotifier extends StateNotifier<LogsState> {
  final LogRepository _repository;
  final int? _driverId;
  final Ref? _ref;

  LogsNotifier(this._repository, this._driverId, [this._ref])
    : super(const LogsState()) {
    if (_driverId != null) {
      loadLogs();
    }
  }

  Future<void> loadLogs({bool refresh = false}) async {
    if (_driverId == null) return;
    if (state.isLoading && !refresh) return;
    if (!refresh && state.hasReachedMax) return;

    final isFirstLoad = state.logs.isEmpty || refresh;
    if (isFirstLoad) {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        clearLoadMoreError: true,
      );
    } else {
      state = state.copyWith(isLoading: true, clearLoadMoreError: true);
    }

    final currentPage = refresh ? 0 : state.page;
    const pageSize = 20;

    final result = await _repository.getDailyLogs(
      driverId: _driverId,
      page: currentPage,
      size: pageSize,
    );

    if (!mounted) return;

    result.match(
      (failure) {
        final isNetworkFailure =
            failure is NetworkFailure || failure.message == 'noInternet';
        if (isFirstLoad) {
          state = isNetworkFailure
              ? state.copyWith(isLoading: false)
              : state.copyWith(isLoading: false, error: failure.message);
        } else {
          state = state.copyWith(
            isLoading: false,
            loadMoreError: failure.message,
          );
        }
      },
      (page) {
        final newLogs = page.logs;
        final mergedLogs = refresh ? newLogs : [...state.logs, ...newLogs];
        // Deduplicate by ID just in case
        final uniqueLogs = <DailyLogId, DailyLog>{};
        for (final log in mergedLogs) {
          uniqueLogs[log.id] = log;
        }

        state = state.copyWith(
          isLoading: false,
          logs: uniqueLogs.values.toList(),
          page: currentPage + 1,
          // الترقيم الموحّد: `hasNext` من الخادم هو الفيصل.
          hasReachedMax: !page.hasNext,
          clearError: true,
          clearLoadMoreError: true,
        );
      },
    );
  }

  /// تحديد سجل محدد للتفاصيل ثم جلب أحداثه.
  ///
  /// قائمة `GET /eld/daily-logs` لا تتضمن الأحداث؛ لذلك تُجلب عند فتح اليوم
  /// من `GET /eld/daily-logs/{id}/events`. يتولى backend استخدام
  /// `/graph-grid` كمسار توافق إذا لم يكن `/events` مدعوماً على الخادم.
  void selectLog(DailyLog log) {
    state = state.copyWith(
      selectedLog: log,
      clearEventsError: true,
      clearServerForm: true,
    );
    _applyRowToLiveDashboard(log);
    // التفاصيل ثم النموذج بالترتيب: النموذج (`/form`) أعلى سلطة من صف
    // القائمة، فيُطبَّق أخيراً مهما تأخرت أو سبقت استجابات الشبكة.
    unawaited(_loadSelectedSources(log));
    loadSelectedLogEvents();
  }

  Future<void> _loadSelectedSources(DailyLog log) async {
    await loadSelectedLogDetail();
    if (!mounted) return;
    if (state.selectedLog?.id != log.id) return;
    await loadSelectedForm();
  }

  /// تطبيق صف السجل على الحالة الحية — لسجل اليوم حصراً، وبلا اختلاق.
  void _applyRowToLiveDashboard(DailyLog log) {
    if (!log.today) return;
    if (log.trailers.isEmpty &&
        log.shippingDocuments.isEmpty &&
        (log.vehicleName == null || log.vehicleName!.isEmpty)) {
      return;
    }
    _ref
        ?.read(dashboardDataProvider.notifier)
        .applyServerForm(
          DailyFormData(
            vehicleUniqueId: log.uniqueId.isNotEmpty ? log.uniqueId : null,
            vehicleName: log.vehicleName,
            trailers: log.trailers,
            shippingDocuments: log.shippingDocuments,
          ),
        );
  }

  /// نموذج اليوم المحفوظ في الخادم (`GET /eld/daily-logs/{id}/form`) —
  /// يُطبق على حقول النموذج في لوحة القيادة ليقرأها تبويب النموذج بدل
  /// بيانات جلسة قديمة. الفشل صامت: تبقى قيم اللوحة الحالية ولا تُختلق
  /// بيانات، والقوائم الفارغة تُترك كما هي.
  Future<void> loadSelectedForm() async {
    final log = state.selectedLog;
    if (log == null) return;
    final result = await _repository.getForm(log.id);
    if (!mounted) return;
    if (state.selectedLog?.id != log.id) return; // فُتح يوم آخر أثناء الانتظار

    result.match(
      (_) {}, // فشل جلب النموذج لا يمسح المعروض ولا يخترع بيانات.
      (form) {
        if (form == null) return; // لا نموذج محفوظ على الخادم لهذا اليوم.
        state = state.copyWith(serverForm: form);
        if (log.today) {
          _ref?.read(dashboardDataProvider.notifier).applyServerForm(form);
        }
      },
    );
  }

  /// نموذج السجل المحدد المعروض، وإلا صف السجل نفسه — أساس أي تعديل
  /// محلي لسجل سابق، بلا اختلاق قيم.
  DailyFormData _selectedFormBase(DailyLog current) {
    return state.serverForm ??
        DailyFormData(
          vehicleUniqueId: current.uniqueId.isNotEmpty
              ? current.uniqueId
              : null,
          vehicleName: current.vehicleName,
          trailers: current.trailers,
          shippingDocuments: current.shippingDocuments,
        );
  }

  /// تعديل قوائم النموذج (المقطورات/وثائق الشحن) للسجل المحدد عندما لا
  /// يكون سجل اليوم: يُحدَّث نموذج الخادم المعروض بذلك فيبقى التعديل
  /// خاصاً بهذا السجل ولا يتسرب إلى الحالة الحية ولا إلى سجل آخر.
  void updateSelectedFormLists({
    List<String>? trailers,
    List<String>? shippingDocuments,
  }) {
    final current = state.selectedLog;
    if (current == null || current.today) return;
    final base = _selectedFormBase(current);
    state = state.copyWith(
      serverForm: DailyFormData(
        vehicleId: base.vehicleId,
        vehicleUniqueId: base.vehicleUniqueId,
        vehicleName: base.vehicleName,
        coDriverId: base.coDriverId,
        coDriverName: base.coDriverName,
        trailers: trailers ?? base.trailers,
        shippingDocuments: shippingDocuments ?? base.shippingDocuments,
      ),
    );
  }

  /// اختيار المركبة لسجل سابق يبقى على نموذج ذلك السجل ولا يمس الحالة
  /// الحية (لوحة القيادة تخص سجل اليوم حصراً).
  void updateSelectedFormVehicle({
    required int? vehicleId,
    required String vehicleUniqueId,
    required String vehicleName,
  }) {
    final current = state.selectedLog;
    if (current == null || current.today) return;
    final base = _selectedFormBase(current);
    state = state.copyWith(
      serverForm: DailyFormData(
        vehicleId: vehicleId,
        vehicleUniqueId: vehicleUniqueId.isEmpty ? null : vehicleUniqueId,
        vehicleName: vehicleName.isEmpty ? null : vehicleName,
        coDriverId: base.coDriverId,
        coDriverName: base.coDriverName,
        trailers: base.trailers,
        shippingDocuments: base.shippingDocuments,
      ),
    );
  }

  /// اختيار السائق المساعد لسجل سابق يبقى على نموذج ذلك السجل وحده.
  void updateSelectedFormCoDriver({
    required int? coDriverId,
    required String coDriverName,
  }) {
    final current = state.selectedLog;
    if (current == null || current.today) return;
    final base = _selectedFormBase(current);
    state = state.copyWith(
      serverForm: DailyFormData(
        vehicleId: base.vehicleId,
        vehicleUniqueId: base.vehicleUniqueId,
        vehicleName: base.vehicleName,
        coDriverId: coDriverId,
        coDriverName: coDriverName.isEmpty ? null : coDriverName,
        trailers: base.trailers,
        shippingDocuments: base.shippingDocuments,
      ),
    );
  }

  /// تفاصيل السجل من الخادم (`GET /eld/daily-logs/{id}`) — مصدر الحقيقة
  /// لبيانات الترويسة (السائق/المركبة/الناقل/العناوين/الشاحنات). صف
  /// القائمة يبقى معروضاً حتى يصل الرد، والفشل هنا صامت: الأحداث لها
  /// مسار خطأها الخاص، وبيانات الصف لا تُختلع محلياً أبداً.
  Future<void> loadSelectedLogDetail() async {
    final log = state.selectedLog;
    if (log == null) return;
    final result = await _repository.getLogById(log.id);
    if (!mounted) return;
    if (state.selectedLog?.id != log.id) return; // فُتح يوم آخر أثناء الانتظار

    result.match(
      (_) {}, // فشل التفاصيل لا يمسح المعروض ولا يخترع بيانات.
      (fresh) {
        // أحداث graph-grid تُحفظ — التفاصيل والحدثان يتكاملان لا يتنافسان.
        _replaceSelected(fresh.copyWith(events: state.selectedLog!.events));
        _applyRowToLiveDashboard(fresh);
      },
    );
  }

  /// (إعادة) جلب أحداث السجل المحدد. آمنة للاستدعاء من زر «إعادة المحاولة».
  Future<void> loadSelectedLogEvents() async {
    final log = state.selectedLog;
    if (log == null) return;

    state = state.copyWith(isLoadingEvents: true, clearEventsError: true);
    final result = await _repository.getEvents(log.id, log.date);
    if (!mounted) return;
    // المستخدم قد يكون فتح يوماً آخر أثناء الانتظار.
    if (state.selectedLog?.id != log.id) return;

    result.match(
      (failure) {
        // Inspection views must distinguish an empty day from an event-load
        // failure, including offline/network failures, so they can offer retry.
        state = state.copyWith(
          isLoadingEvents: false,
          eventsError: failure.message,
        );
      },
      (events) {
        // نحافظ على حالة التوسيع الحالية للأحداث ذات المعرّف نفسه.
        final expanded = {
          for (final e in state.selectedLog!.events)
            if (e.isExpanded) e.id,
        };
        final merged = events
            .map(
              (e) => expanded.contains(e.id) ? e.copyWith(isExpanded: true) : e,
            )
            .toList();
        _replaceSelected(state.selectedLog!.copyWith(events: merged));
        state = state.copyWith(isLoadingEvents: false, clearEventsError: true);
      },
    );
  }

  /// يحدّث السجل المحدد ونسخته داخل القائمة معاً (مصدر حقيقة واحد).
  void _replaceSelected(DailyLog updatedLog) {
    state = state.copyWith(
      selectedLog: updatedLog,
      logs: state.logs
          .map((l) => l.id == updatedLog.id ? updatedLog : l)
          .toList(),
    );
  }

  /// تبديل توسيع حدث
  void toggleEventExpansion(String eventId) {
    if (state.selectedLog == null) return;

    final updatedEvents = state.selectedLog!.events.map((e) {
      if (e.id == eventId) {
        return e.copyWith(isExpanded: !e.isExpanded);
      }
      return e;
    }).toList();

    final updatedLog = state.selectedLog!.copyWith(events: updatedEvents);

    // Keep the selected log and the matching item in `logs` in sync. The
    // detail page resolves the active log from that list first, so updating
    // only `selectedLog` leaves the event tile with a stale `isExpanded`.
    _replaceSelected(updatedLog);
  }

  /// إضافة حدث جديد للسجل المحدد (POST /eld/duty-status، أو محلياً دون اتصال).
  Future<Either<Failure, void>> addEvent(
    LogEvent event, {
    String? reason,
  }) async {
    if (state.selectedLog == null) {
      return const Left(ServerFailure(message: 'No log selected'));
    }

    final result = _driverId != null
        ? await _repository.addEvent(
            event,
            reason: reason,
            ownerDriverId: _driverId,
          )
        : await _repository.addEvent(event, reason: reason);
    if (!mounted) return const Left(ServerFailure(message: 'Unmounted'));

    return result.fold((failure) => Left(failure), (ok) {
      if (!ok) {
        return const Left(ServerFailure(message: 'Failed to save event'));
      }
      _replaceSelected(
        state.selectedLog!.copyWith(
          events: <LogEvent>[...state.selectedLog!.events, event],
        ),
      );
      unawaited(loadSelectedLogEvents());
      return const Right(null);
    });
  }

  /// تعديل حدث (العقد الموحّد: PUT /eld/daily-logs/{logId}/events/{eventId}
  /// مع سبب إلزامي؛ الرواسب القديمة تعود لمسار /eld/duty-status).
  Future<Either<Failure, void>> updateEvent(
    LogEvent event, {
    required String reason,
  }) async {
    if (state.selectedLog == null) {
      return const Left(ServerFailure(message: 'No log selected'));
    }

    final confirmed = _driverId != null
        ? await _repository.updateEvent(
            event,
            reason: reason,
            logId: state.selectedLog!.id,
            ownerDriverId: _driverId,
          )
        : await _repository.updateEvent(
            event,
            reason: reason,
            logId: state.selectedLog!.id,
          );
    if (!mounted) return const Left(ServerFailure(message: 'Unmounted'));

    return confirmed.fold((failure) => Left(failure), (persistedEvent) {
      if (persistedEvent == null) {
        _replaceSelected(
          state.selectedLog!.copyWith(
            events: state.selectedLog!.events
                .map((e) => e.id == event.id ? event : e)
                .toList(),
          ),
        );
      } else {
        _replaceSelected(
          state.selectedLog!.copyWith(
            events: state.selectedLog!.events
                .map((e) => e.id == persistedEvent.id ? persistedEvent : e)
                .toList(),
          ),
        );
      }
      unawaited(loadSelectedLogEvents());
      return const Right(null);
    });
  }

  /// تحديث سجل بالكامل (مثل إكمال النموذج)
  void updateLog(DailyLog updatedLog) {
    if (state.selectedLog?.id == updatedLog.id) {
      _replaceSelected(updatedLog);
      return;
    }
    state = state.copyWith(
      logs: state.logs
          .map((log) => log.id == updatedLog.id ? updatedLog : log)
          .toList(),
    );
  }
}

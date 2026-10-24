import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/dvir_repository_providers.dart';
import '../../domain/dvir_catalog.dart';
import '../../domain/dvir_vehicle.dart';
import '../../domain/entities/dvir_defect.dart';
import '../../domain/entities/dvir_report.dart';
import '../../domain/repositories/dvir_repository.dart';
import '../../../../core/utils/logger.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../../vehicle/presentation/providers/vehicle_provider.dart';
import '../../../vehicle/domain/entities/vehicle.dart';

// --- State and Notifier ---

/// حالة شاشة DVIR
class DvirState {
  final List<DvirReport> reports;
  final DvirReport? currentReport;
  final bool isLoading;

  /// مستقل عن [isLoading]: يُضبط فقط أثناء إرسال تقرير جديد.
  /// يمنع تأثير الإرسال على حالة تحميل قائمة التقارير.
  final bool isSubmitting;
  final String? error;

  final DvirReport? previousDvir;
  final String? previousVehicleId;
  final bool previousLookupDone;
  final bool previousLookupFailed;

  /// Whether [reports] represents an authoritative vehicle-scoped list read,
  /// including a successful empty read. Used as the §396.13 fallback when the
  /// dedicated pre-trip endpoint is unavailable.
  final bool reportsLoaded;

  const DvirState({
    this.reports = const [],
    this.currentReport,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.previousDvir,
    this.previousVehicleId,
    this.previousLookupDone = false,
    this.previousLookupFailed = false,
    this.reportsLoaded = false,
  });

  /// Previous report for [vehicleId] that still needs the §396.13 review.
  /// Prefers the pre-trip endpoint; falls back to the vehicle-scoped list
  /// only when that lookup failed or has not answered yet.
  DvirReport? previousToReview(String vehicleId) {
    if (previousLookupDone &&
        !previousLookupFailed &&
        previousVehicleId == vehicleId) {
      final p = previousDvir;
      return (p != null && p.nextDriverReviewed != true) ? p : null;
    }
    return reports
        .where((r) => r.vehicleId == vehicleId)
        .cast<DvirReport?>()
        .firstWhere((r) => r!.nextDriverReviewed != true, orElse: () => null);
  }

  DvirState copyWith({
    List<DvirReport>? reports,
    DvirReport? currentReport,
    bool clearCurrentReport = false,
    bool? isLoading,
    bool? isSubmitting,
    // Sentinel to distinguish "clear error" from "keep current error".
    Object? error = _keepError,
    DvirReport? previousDvir,
    bool clearPreviousDvir = false,
    String? previousVehicleId,
    bool? previousLookupDone,
    bool? previousLookupFailed,
    bool? reportsLoaded,
  }) {
    return DvirState(
      reports: reports ?? this.reports,
      currentReport: clearCurrentReport
          ? null
          : (currentReport ?? this.currentReport),
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: identical(error, _keepError) ? this.error : (error as String?),
      previousDvir: clearPreviousDvir
          ? null
          : (previousDvir ?? this.previousDvir),
      previousVehicleId: previousVehicleId ?? this.previousVehicleId,
      previousLookupDone: previousLookupDone ?? this.previousLookupDone,
      previousLookupFailed: previousLookupFailed ?? this.previousLookupFailed,
      reportsLoaded: reportsLoaded ?? this.reportsLoaded,
    );
  }
}

// Sentinel value so copyWith can distinguish null from "not provided".
const Object _keepError = Object();

/// يحوّل كيانات مركبة الميزة الأخرى إلى المرجع الضيق الذي تستهلكه قاعدة
/// النطاق — التحويل هنا، القاعدة في `domain/dvir_vehicle.dart`.
List<DvirVehicleRef> vehicleRefsForDvir(List<Vehicle> vehicles) => [
  for (final vehicle in vehicles)
    DvirVehicleRef(
      id: vehicle.id,
      uniqueId: vehicle.uniqueId,
      deviceId: vehicle.deviceId,
    ),
];

/// مزود DVIR — autoDispose so the provider is rebuilt fresh every time the
/// screen is re-opened, and released when no widget is listening.
final dvirProvider = StateNotifierProvider.autoDispose<DvirNotifier, DvirState>(
  (ref) {
    final repository = ref.watch(dvirRepositoryProvider);
    final vehicleState = ref.watch(vehicleProvider);
    final selectedVehicle = vehicleState.selectedVehicle;
    final dashboardVehicle = ref.watch(dashboardDataProvider).vehicleId;
    final vehicleId = resolveDvirVehicleUniqueId(
      vehicles: vehicleRefsForDvir(vehicleState.vehicles),
      selectedUniqueId: selectedVehicle?.uniqueId,
      dashboardVehicleId: dashboardVehicle,
    );

    return DvirNotifier(repository: repository, vehicleId: vehicleId);
  },
);

class DvirNotifier extends StateNotifier<DvirState> {
  final DvirRepository _repository;
  String? _vehicleId;
  Future<void>? _inFlightLoad;
  int _listSequence = 0;
  int _detailsSequence = 0;
  final Map<String, Future<void>> _previousLoads = {};
  int _previousSequence = 0;

  DvirNotifier({required DvirRepository repository, String? vehicleId})
    : _repository = repository,
      _vehicleId = vehicleId,
      super(const DvirState()) {
    _loadDvirs();
  }

  Future<void> refresh() => _loadDvirs();

  /// Switches the list source when the driver picks another vehicle inside the
  /// DVIR form (without mutating the dashboard). In-flight answers for the old
  /// vehicle are fenced off so they cannot overwrite the new vehicle's list.
  Future<void> setVehicle(String? vehicleId) async {
    final normalized = vehicleId != null && !isUnassignedVehicleId(vehicleId)
        ? vehicleId.trim()
        : null;
    if (normalized == _vehicleId) return;
    _vehicleId = normalized;
    _listSequence++;
    _inFlightLoad = null;
    state = state.copyWith(
      reports: const [],
      reportsLoaded: false,
      clearPreviousDvir: true,
      previousLookupDone: false,
      previousLookupFailed: false,
    );
    await _loadDvirs();
  }

  /// §396.13 source of truth: `GET /eld/dvir/pre-trip/{uniqueId}`.
  /// A failed read leaves the list fallback in force (see
  /// [DvirState.previousToReview]); nothing is invented.
  ///
  /// Concurrent calls for the same vehicle share one request. A slower answer
  /// for an older vehicle is discarded (sequence guard) so it cannot overwrite
  /// the answer for the vehicle the driver is currently inspecting.
  Future<void> loadPreviousDvir(String vehicleId) {
    if (isUnassignedVehicleId(vehicleId)) {
      AppLogger.debug(
        'DVIR previous inspection load skipped: vehicle uniqueId is unavailable.',
      );
      return Future.value();
    }
    final key = vehicleId.trim();
    final existing = _previousLoads[key];
    if (existing != null) return existing;

    final future = _fetchPreviousDvir(key);
    _previousLoads[key] = future;
    return future.whenComplete(() {
      if (identical(_previousLoads[key], future)) {
        _previousLoads.remove(key);
      }
    });
  }

  Future<void> _fetchPreviousDvir(String vehicleId) async {
    final requestId = ++_previousSequence;
    AppLogger.debug('DVIR previous inspection request started.');
    final result = await _repository.getPreviousDvir(vehicleId);
    if (!mounted || requestId != _previousSequence) return;
    result.fold(
      (_) => state = state.copyWith(
        previousVehicleId: vehicleId,
        previousLookupDone: true,
        previousLookupFailed: true,
        clearPreviousDvir: true,
      ),
      (report) => state = state.copyWith(
        previousVehicleId: vehicleId,
        previousLookupDone: true,
        previousLookupFailed: false,
        previousDvir: report,
        clearPreviousDvir: report == null,
      ),
    );
  }

  /// Resolves the §396.13 previous-report question before a report is signed.
  ///
  /// Returns `true` only when the answer is authoritative:
  /// - the pre-trip endpoint answered (with or without a report), or
  /// - the vehicle-scoped report list is available as the documented fallback.
  ///
  /// `false` means the obligation is unknown (e.g. offline with no cache);
  /// the caller must not submit silently.
  Future<bool> ensurePreviousDvir(String vehicleId) async {
    final key = vehicleId.trim();
    if (isUnassignedVehicleId(key)) return false;
    await loadPreviousDvir(key);
    if (!mounted) return false;

    final authoritative =
        state.previousLookupDone &&
        state.previousVehicleId == key &&
        !state.previousLookupFailed;
    if (authoritative) return true;

    // A vehicle-scoped list that was actually loaded is the supported
    // fallback when the dedicated endpoint is unavailable. A successful empty
    // read is still an answer ("no reports"), not an unknown state.
    if (state.reportsLoaded && key == _vehicleId?.trim()) return true;
    return state.reports.any((report) => report.vehicleId == key);
  }

  Future<void> _loadDvirs({bool background = false}) async {
    if (_inFlightLoad != null) return _inFlightLoad!;
    final future = _performLoadDvirs(background: background);
    _inFlightLoad = future;
    try {
      await future;
    } finally {
      if (identical(_inFlightLoad, future)) _inFlightLoad = null;
    }
  }

  Future<void> _performLoadDvirs({bool background = false}) async {
    final requestId = ++_listSequence;
    // Explicitly clear the error when starting a fresh load.
    if (!background) {
      state = state.copyWith(isLoading: true, error: null);
    }

    // The endpoint is scoped by Traccar uniqueId; never request an unfiltered
    // list when there is no selected vehicle.
    final vehicleId = (_vehicleId != null && !isUnassignedVehicleId(_vehicleId))
        ? _vehicleId
        : null;
    if (vehicleId == null) {
      AppLogger.debug(
        'DVIR reports request skipped: vehicle uniqueId is unavailable.',
      );
      if (mounted && requestId == _listSequence) {
        state = state.copyWith(isLoading: false, error: 'dvirVehicleIdMissing');
      }
      return;
    }
    AppLogger.debug('DVIR reports request started.');
    try {
      final result = await _repository.getDvirReports(vehicleId);
      if (!mounted || requestId != _listSequence) return;

      result.fold(
        (failure) {
          state = state.copyWith(isLoading: false, error: failure.message);
        },
        (reports) => state = state.copyWith(
          isLoading: false,
          reports: reports,
          reportsLoaded: true,
          error: null,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'DVIR reports request failed unexpectedly',
        error,
        stackTrace,
      );
      if (mounted && requestId == _listSequence) {
        state = state.copyWith(isLoading: false, error: 'dvirListLoadFailed');
      }
    }
  }

  /// إنشاء تقرير جديد وإرساله. الحالة الرسمية من الكيان نفسه.
  ///
  /// Any thrown error (storage, queue, backend adapter) resets
  /// [DvirState.isSubmitting] and surfaces a generic localized failure; a
  /// stuck flag would otherwise block every later submission in this session.
  Future<bool> createReport(DvirReport report, {required int driverId}) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final result = await _repository.submitDvirReport(
        report,
        driverId: driverId,
      );
      if (!mounted) return false;
      return await result.fold(
        (failure) {
          state = state.copyWith(isSubmitting: false, error: failure.message);
          return false;
        },
        (_) async {
          state = state.copyWith(isSubmitting: false);
          // Refresh and await so the updated list is in state immediately.
          await _loadDvirs();
          return true;
        },
      );
    } catch (error, stackTrace) {
      AppLogger.error('DVIR submission failed unexpectedly', error, stackTrace);
      if (mounted) {
        state = state.copyWith(
          isSubmitting: false,
          error: 'dvirSubmissionFailed',
        );
      }
      return false;
    } finally {
      if (mounted && state.isSubmitting) {
        state = state.copyWith(isSubmitting: false);
      }
    }
  }

  /// مراجعة وتوقيع السائق التالي. الرسالة تُرجع للواجهة لتعرضها؛
  /// null = نجاح. التحقق من التوقيع الأولي في النموذج قبل الوصول إلى هنا.
  Future<String?> reviewDvir({
    required String dvirId,
    required int reviewingDriverId,
    required String reviewingDriverName,
    required String signatureData,
    required bool driverAgreed,
    String? reviewNotes,
  }) async {
    if (signatureData.trim().isEmpty) {
      // دفاع داخلي: النموذج يمنع الوصول بتوقيع فارغ أصلاً.
      const message = 'signature required';
      state = state.copyWith(error: message);
      return message;
    }
    state = state.copyWith(isSubmitting: true, error: null);
    String? reviewFailure;
    try {
      final result = await _repository.reviewDvir(
        dvirId: dvirId,
        reviewingDriverId: reviewingDriverId,
        reviewingDriverName: reviewingDriverName,
        signatureData: signatureData,
        driverAgreed: driverAgreed,
        reviewNotes: reviewNotes,
      );
      if (mounted) {
        reviewFailure = result.fold(
          (failure) {
            state = state.copyWith(isSubmitting: false, error: failure.message);
            return failure.message;
          },
          (_) {
            // Update the affected report in memory instead of re-fetching.
            final updatedReports = state.reports.map((r) {
              if (r.id != dvirId) return r;
              return r.copyWith(
                nextDriverReviewed: true,
                reviewingDriverName: reviewingDriverName,
              );
            }).toList();

            // §396.13 is satisfied for this session: the same previous report
            // must not be offered for review again when the form reopens.
            final previous = state.previousDvir;
            final updatedPrevious = previous != null && previous.id == dvirId
                ? previous.copyWith(
                    nextDriverReviewed: true,
                    reviewingDriverName: reviewingDriverName,
                  )
                : previous;

            state = state.copyWith(
              isSubmitting: false,
              error: null,
              reports: updatedReports,
              previousDvir: updatedPrevious,
              clearPreviousDvir: updatedPrevious == null,
            );
            return null;
          },
        );
      }
    } catch (error, stackTrace) {
      AppLogger.error('DVIR review failed unexpectedly', error, stackTrace);
      reviewFailure = 'dvirReviewFailed';
      if (mounted) {
        state = state.copyWith(isSubmitting: false, error: reviewFailure);
      }
    } finally {
      if (mounted && state.isSubmitting) {
        state = state.copyWith(isSubmitting: false);
      }
    }
    return reviewFailure;
  }

  /// استرجاع تفاصيل تقرير DVIR محدد. التحميل صامت (بلا مؤشر عام) —
  /// الشاشة التي تطلب التفاصيل تدير حالتها المحلية.
  Future<void> loadDvirDetails(String dvirId) async {
    // A slower answer for an older detail screen must not overwrite the report
    // the driver opened last (e.g. summary -> detail navigation).
    final requestId = ++_detailsSequence;
    // Clear stale currentReport and error before loading.
    state = state.copyWith(clearCurrentReport: true, error: null);
    try {
      final result = await _repository.getDvirDetails(dvirId);
      if (!mounted || requestId != _detailsSequence) return;

      result.fold(
        (failure) => state = state.copyWith(error: failure.message),
        (report) => state = state.copyWith(currentReport: report, error: null),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'DVIR details request failed unexpectedly',
        error,
        stackTrace,
      );
      if (mounted && requestId == _detailsSequence) {
        state = state.copyWith(error: 'dvirDetailsLoadFailed');
      }
    }
  }
}

/// `GET /eld/dvir/catalog` — the §396.11 item list, عبر المستودع.
/// keepAlive for 30 min so repeated dialog opens don't hit the network.
final dvirCatalogProvider = FutureProvider.autoDispose<List<DvirCatalogItem>>((
  ref,
) async {
  // Keep the catalog alive for 30 minutes after last use.
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 30), link.close);
  // بلا إلغاء كان المؤقت يبقى معلقاً حتى بعد تخلص المزود —
  // ويفجّر فحص timersPending في الاختبارات.
  ref.onDispose(timer.cancel);

  final result = await ref.watch(dvirRepositoryProvider).getDefectsCatalog();
  return result.fold((f) => throw f, (items) => items);
});

/// العيوب النشطة لمركبة السائق (`GET /eld/dvir/defects/device/{uniqueId}`)
/// — الهوية من المركبة المحددة (وليس معرف تتبع هاتف السائق). القائمة الفارغة
/// أو الفشل يعني "لا قسم يُعرض" — لا يكسر شاشة القائمة.
final activeVehicleDefectsProvider = FutureProvider.autoDispose<List<DvirDefect>>(
  (ref) async {
    final vehicleState = ref.watch(vehicleProvider);
    final selectedVehicle = vehicleState.selectedVehicle;
    final dashboardVehicle = ref.watch(dashboardDataProvider).vehicleId;
    final vehicleId = resolveDvirVehicleUniqueId(
      vehicles: vehicleRefsForDvir(vehicleState.vehicles),
      selectedUniqueId: selectedVehicle?.uniqueId,
      dashboardVehicleId: dashboardVehicle,
    );

    if (vehicleId == null || isUnassignedVehicleId(vehicleId)) {
      AppLogger.debug(
        'DVIR active defects request skipped: vehicle uniqueId is unavailable.',
      );
      throw StateError('dvirVehicleIdMissing');
    }
    AppLogger.debug('DVIR active defects request started.');
    final result = await ref
        .watch(dvirRepositoryProvider)
        .getActiveDefects(uniqueId: vehicleId);
    return result.fold((failure) => throw failure, (defects) => defects);
  },
);

/// تفاصيل عيب واحد (`GET /eld/dvir/defects/{id}`) — القراءة عبر المستودع
/// فقط؛ نوافذ العرض لا تلمس المستودع مباشرة. من يريد "الفشل يُبقي
/// المعروض" يوفّر قيمة ابتدائية ويتجاهل خطأ هذا المزوّد.
final dvirDefectDetailsProvider = FutureProvider.autoDispose
    .family<DvirDefect, int>((ref, defectId) async {
      final result = await ref
          .watch(dvirRepositoryProvider)
          .getDefectDetails(defectId);
      return result.fold((failure) => throw failure, (defect) => defect);
    });

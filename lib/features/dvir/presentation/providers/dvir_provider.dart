import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/dvir_repository_providers.dart';
import '../../domain/dvir_catalog.dart';
import '../../domain/dvir_vehicle.dart';
import '../../domain/entities/dvir_defect.dart';
import '../../domain/entities/dvir_report.dart';
import '../../domain/repositories/dvir_repository.dart';
import '../../../../core/services/tracking_config_storage_service.dart';

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
  });

  /// Previous report for [vehicleId] that still needs the §396.13 review.
  /// Prefers the pre-trip endpoint; falls back to the vehicle-scoped list
  /// only when that lookup failed or has not answered yet.
  DvirReport? previousToReview(String vehicleId) {
    if (previousLookupDone && !previousLookupFailed && previousVehicleId == vehicleId) {
      final p = previousDvir;
      return (p != null && p.nextDriverReviewed != true) ? p : null;
    }
    return reports
        .where((r) => r.vehicleId == vehicleId)
        .cast<DvirReport?>()
        .firstWhere(
          (r) => r!.nextDriverReviewed != true,
          orElse: () => null,
        );
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
  }) {
    return DvirState(
      reports: reports ?? this.reports,
      currentReport:
          clearCurrentReport ? null : (currentReport ?? this.currentReport),
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: identical(error, _keepError) ? this.error : (error as String?),
      previousDvir: clearPreviousDvir ? null : (previousDvir ?? this.previousDvir),
      previousVehicleId: previousVehicleId ?? this.previousVehicleId,
      previousLookupDone: previousLookupDone ?? this.previousLookupDone,
      previousLookupFailed: previousLookupFailed ?? this.previousLookupFailed,
    );
  }
}

// Sentinel value so copyWith can distinguish null from "not provided".
const Object _keepError = Object();

/// مزود DVIR — autoDispose so the provider is rebuilt fresh every time the
/// screen is re-opened, and released when no widget is listening.
final dvirProvider =
    StateNotifierProvider.autoDispose<DvirNotifier, DvirState>((ref) {
  final repository = ref.watch(dvirRepositoryProvider);
  final storageService = ref.watch(trackingConfigStorageProvider);
  final notifier = DvirNotifier(repository: repository, storageService: storageService);
  // Load lazily here (outside the constructor) so the constructor is pure.
  notifier.refresh();
  return notifier;
});

class DvirNotifier extends StateNotifier<DvirState> {
  final DvirRepository _repository;
  final TrackingConfigStorageService _storageService;

  DvirNotifier({
    required DvirRepository repository,
    required TrackingConfigStorageService storageService,
  })  : _repository = repository,
        _storageService = storageService,
        super(const DvirState());

  Future<void> refresh() => _loadDvirs();

  /// §396.13 source of truth: `GET /eld/dvir/pre-trip/{uniqueId}`.
  /// A failed read leaves the list fallback in force (see
  /// [DvirState.previousToReview]); nothing is invented.
  Future<void> loadPreviousDvir(String vehicleId) async {
    final result = await _repository.getPreviousDvir(vehicleId);
    if (!mounted) return;
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

  Future<void> _loadDvirs() async {
    // Explicitly clear the error when starting a fresh load.
    state = state.copyWith(isLoading: true, error: null);

    // معرّف غير معيّن (فارغ) يمر كما هو؛ المستودع هو من يعامل الفراغ.
    final vehicleId = _storageService.deviceId;
    final result = await _repository.getDvirReports(vehicleId);

    if (mounted) {
      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          error: failure.message,
        ),
        (reports) => state = state.copyWith(
          isLoading: false,
          reports: reports,
          error: null,
        ),
      );
    }
  }

  /// إنشاء تقرير جديد وإرساله
  Future<bool> createReport(
    DvirReport report, {
    required int driverId,
    required DvirConditionStatus status,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    final result = await _repository.submitDvirReport(
      report,
      driverId: driverId,
      status: status,
    );
    if (!mounted) return false;
    return result.fold(
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
      state = state.copyWith(isSubmitting: false, error: message);
      return message;
    }
    state = state.copyWith(isSubmitting: true, error: null);
    final result = await _repository.reviewDvir(
      dvirId: dvirId,
      reviewingDriverId: reviewingDriverId,
      reviewingDriverName: reviewingDriverName,
      signatureData: signatureData,
      driverAgreed: driverAgreed,
      reviewNotes: reviewNotes,
    );
    if (!mounted) return null;
    return result.fold(
      (failure) {
        state = state.copyWith(isSubmitting: false, error: failure.message);
        return failure.message;
      },
      (_) {
        state = state.copyWith(isSubmitting: false, error: null);
        return null;
      },
    );
  }

  /// استرجاع تفاصيل تقرير DVIR محدد. التحميل صامت (بلا مؤشر عام) —
  /// الشاشة التي تطلب التفاصيل تدير حالتها المحلية.
  Future<void> loadDvirDetails(String dvirId) async {
    // Clear stale currentReport and error before loading.
    state = state.copyWith(clearCurrentReport: true, error: null);
    final result = await _repository.getDvirDetails(dvirId);

    if (mounted) {
      result.fold(
        (failure) => state = state.copyWith(error: failure.message),
        (report) => state = state.copyWith(
          currentReport: report,
          error: null,
        ),
      );
    }
  }
}

/// `GET /eld/dvir/catalog` — the §396.11 item list, عبر المستودع.
/// keepAlive for 30 min so repeated dialog opens don't hit the network.
final dvirCatalogProvider = FutureProvider.autoDispose<List<DvirCatalogItem>>((ref) async {
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
/// — الهوية من الجهاز المتصل (نفس مصدر قائمة الفحوصات). القائمة الفارغة
/// أو الفشل يعني "لا قسم يُعرض" — لا يكسر شاشة القائمة.
final activeVehicleDefectsProvider =
    FutureProvider.autoDispose<List<DvirDefect>>((ref) async {
  final vehicleId = ref.watch(trackingConfigStorageProvider).deviceId;
  if (isUnassignedVehicleId(vehicleId)) return const [];
  final result = await ref
      .watch(dvirRepositoryProvider)
      .getActiveDefects(uniqueId: vehicleId);
  return result.fold((failure) => throw failure, (defects) => defects);
});

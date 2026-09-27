import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/dvir_repository_providers.dart';
import '../../domain/dvir_catalog.dart';
import '../../domain/entities/dvir_report.dart';
import '../../domain/repositories/dvir_repository.dart';
import '../../../../core/services/tracking_config_storage_service.dart';

// --- State and Notifier ---

/// حالة شاشة DVIR
class DvirState {
  final List<DvirReport> reports;
  final DvirReport? currentReport;
  final bool isLoading;
  final String? error;

  /// Last `GET /eld/dvir/pre-trip/{uniqueId}` answer for [previousVehicleId].
  /// `previousLookupDone && previousDvir == null` = server said none.
  final DvirReport? previousDvir;
  final String? previousVehicleId;
  final bool previousLookupDone;
  final bool previousLookupFailed;

  const DvirState({
    this.reports = const [],
    this.currentReport,
    this.isLoading = false,
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
    for (final r in reports) {
      if (r.vehicleId == vehicleId) return r.nextDriverReviewed != true ? r : null;
    }
    return null;
  }

  DvirState copyWith({
    List<DvirReport>? reports,
    DvirReport? currentReport,
    bool? isLoading,
    String? error,
    DvirReport? previousDvir,
    bool clearPreviousDvir = false,
    String? previousVehicleId,
    bool? previousLookupDone,
    bool? previousLookupFailed,
  }) {
    return DvirState(
      reports: reports ?? this.reports,
      currentReport: currentReport ?? this.currentReport,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      previousDvir: clearPreviousDvir ? null : (previousDvir ?? this.previousDvir),
      previousVehicleId: previousVehicleId ?? this.previousVehicleId,
      previousLookupDone: previousLookupDone ?? this.previousLookupDone,
      previousLookupFailed: previousLookupFailed ?? this.previousLookupFailed,
    );
  }
}

/// مزود DVIR
final dvirProvider = StateNotifierProvider<DvirNotifier, DvirState>((ref) {
  final repository = ref.watch(dvirRepositoryProvider);
  final storageService = ref.watch(trackingConfigStorageProvider);
  return DvirNotifier(repository: repository, storageService: storageService);
});

class DvirNotifier extends StateNotifier<DvirState> {
  final DvirRepository _repository;
  final TrackingConfigStorageService _storageService;

  DvirNotifier({
    required DvirRepository repository,
    required TrackingConfigStorageService storageService,
  })  : _repository = repository,
        _storageService = storageService,
        super(const DvirState()) {
    _loadDvirs();
  }

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
        error: state.error,
      ),
      (report) => state = state.copyWith(
        previousVehicleId: vehicleId,
        previousLookupDone: true,
        previousLookupFailed: false,
        previousDvir: report,
        clearPreviousDvir: report == null,
        error: state.error,
      ),
    );
  }

  Future<void> _loadDvirs() async {
    state = state.copyWith(isLoading: true, error: null);

    final vehicleId = _storageService.deviceId;
    final result = await _repository
        .getDvirReports(vehicleId.isEmpty ? 'unknown_vehicle' : vehicleId);

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
    required String status,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.submitDvirReport(
      report,
      driverId: driverId,
      status: status,
    );
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (_) {
        _loadDvirs();
        return true;
      },
    );
  }

  /// تصديق إصلاح العيوب من قبل الميكانيكي أو الناقل
  Future<void> certifyRepair({
    required String dvirId,
    required String mechanicName,
    required String action,
    String? repairNotes,
    required String mechanicSignature,
  }) async {
    state = state.copyWith(
      isLoading: false,
      error: 'Repair certification is a carrier action and is not available to the driver.',
    );
  }

  /// مراجعة وتوقيع السائق التالي
  Future<String?> reviewDvir({
    required String dvirId,
    required int reviewingDriverId,
    required String reviewingDriverName,
    required String signatureData,
    required bool driverAgreed,
    String? reviewNotes,
  }) async {
    if (signatureData.trim().isEmpty) {
      const message = 'A signature is required to review the previous report.';
      state = state.copyWith(isLoading: false, error: message);
      return message;
    }
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.reviewDvir(
      dvirId: dvirId,
      reviewingDriverId: reviewingDriverId,
      reviewingDriverName: reviewingDriverName,
      signatureData: signatureData,
      driverAgreed: driverAgreed,
      reviewNotes: reviewNotes,
    );
    if (!mounted) return 'Review was interrupted.';
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return failure.message;
      },
      (_) {
        state = state.copyWith(isLoading: false, error: null);
        return null;
      },
    );
  }

  /// استرجاع تفاصيل تقرير DVIR محدد
  Future<void> loadDvirDetails(String dvirId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.getDvirDetails(dvirId);

    if (mounted) {
      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          error: failure.message,
        ),
        (report) => state = state.copyWith(
          isLoading: false,
          currentReport: report,
          error: null,
        ),
      );
    }
  }

  /// تحديث تقرير موجود (للاستخدام المحلي)
  void updateReport(DvirReport report) {
    final updatedReports = state.reports.map((r) {
      return r.id == report.id ? report : r;
    }).toList();
    state = state.copyWith(reports: updatedReports);
  }
}

/// `GET /eld/dvir/catalog` — the §396.11 item list. Not cached across sessions.
final dvirCatalogProvider = FutureProvider<List<DvirCatalogItem>>((ref) async {
  final result = await ref.watch(dvirBackendProviderAlias).getDefectsCatalog();
  return result.fold((error) => throw error, (json) {
    final items = parseDvirCatalog(json);
    if (items == null) {
      throw const FormatException('catalog body is not a list');
    }
    return items;
  });
});

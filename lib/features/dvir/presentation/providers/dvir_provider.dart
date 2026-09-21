import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../backend/contracts/dvir_backend.dart';
import '../../data/repositories/dvir_repository_impl.dart';
import '../../domain/entities/dvir_report.dart';
import '../../domain/repositories/dvir_repository.dart';
import '../../../../core/services/tracking_config_storage_service.dart';

// --- Dependency Injection Providers ---

final dvirBackendProviderAlias = Provider<DvirBackend>((ref) {
  return ref.watch(dvirBackendProvider);
});

final dvirRepositoryProvider = Provider<DvirRepository>((ref) {
  return DvirRepositoryImpl(
    dvirBackend: ref.watch(dvirBackendProviderAlias),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

// --- State and Notifier ---

/// حالة شاشة DVIR
class DvirState {
  final List<DvirReport> reports;
  final DvirReport? currentReport;
  final bool isLoading;
  final String? error;

  const DvirState({
    this.reports = const [],
    this.currentReport,
    this.isLoading = false,
    this.error,
  });

  DvirState copyWith({
    List<DvirReport>? reports,
    DvirReport? currentReport,
    bool? isLoading,
    String? error,
  }) {
    return DvirState(
      reports: reports ?? this.reports,
      currentReport: currentReport ?? this.currentReport,
      isLoading: isLoading ?? this.isLoading,
      error: error,
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
  Future<void> createReport(DvirReport report) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.submitDvirReport(report);

    if (mounted) {
      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          error: failure.message,
        ),
        (_) {
          _loadDvirs(); // Reload to get updated list with server IDs
        },
      );
    }
  }

  /// تصديق إصلاح العيوب من قبل الميكانيكي أو الناقل
  Future<void> certifyRepair({
    required String dvirId,
    required String mechanicName,
    required String action,
    String? repairNotes,
    required String mechanicSignature,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.certifyRepair(
      dvirId: dvirId,
      mechanicName: mechanicName,
      action: action,
      repairNotes: repairNotes,
      mechanicSignature: mechanicSignature,
    );

    if (mounted) {
      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          error: failure.message,
        ),
        (_) {
          _loadDvirs(); // Reload to update state
        },
      );
    }
  }

  /// مراجعة وتوقيع السائق التالي
  Future<void> reviewDvir({
    required String dvirId,
    required int reviewingDriverId,
    required String reviewingDriverName,
    required String signatureData,
    required bool driverAgreed,
    String? reviewNotes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.reviewDvir(
      dvirId: dvirId,
      reviewingDriverId: reviewingDriverId,
      reviewingDriverName: reviewingDriverName,
      signatureData: signatureData,
      driverAgreed: driverAgreed,
      reviewNotes: reviewNotes,
    );

    if (mounted) {
      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          error: failure.message,
        ),
        (_) {
          _loadDvirs(); // Reload to update state
        },
      );
    }
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

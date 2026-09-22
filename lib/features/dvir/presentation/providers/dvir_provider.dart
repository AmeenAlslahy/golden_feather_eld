import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: directives_ordering
import 'package:fpdart/fpdart.dart';

// ARCH-HIGH-01 fix: Import from composition root
import '../../../../app/providers/app_repository_providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/services/tracking_config_storage_service.dart';
import '../../../vehicle/presentation/providers/vehicle_provider.dart';
import '../../domain/entities/dvir_report.dart';
import '../../domain/repositories/dvir_repository.dart';

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
  final vehicleState = ref.watch(vehicleProvider);
  final vehicleId = vehicleState.selectedVehicle?.id ?? storageService.deviceId;
  return DvirNotifier(
    repository: repository,
    storageService: storageService,
    vehicleId: vehicleId,
  );
});

class DvirNotifier extends StateNotifier<DvirState> {
  final DvirRepository _repository;
  final String _vehicleId;

  DvirNotifier({
    required DvirRepository repository,
    TrackingConfigStorageService? storageService,
    String? vehicleId,
  })  : _repository = repository,
        _vehicleId = vehicleId ?? storageService?.deviceId ?? '',
        super(const DvirState()) {
    loadDvirs();
  }

  Future<void> loadDvirs({String? vehicleId}) async {
    state = state.copyWith(isLoading: true, error: null);

    final targetVehicleId = vehicleId ?? _vehicleId;
    final result = await _repository.getDvirReports(targetVehicleId);

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
  Future<Either<Failure, bool>> createReport(DvirReport report) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.submitDvirReport(report);

    if (mounted) {
      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          error: failure.message,
        ),
        (_) {
          loadDvirs(); // Reload to update state
        },
      );
    }
    return result;
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
          loadDvirs(); // Reload to update state
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
          loadDvirs(); // Reload to update state
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
  Future<Either<Failure, bool>> updateReport(DvirReport report) async {
    final updatedReports = state.reports.map((r) {
      return r.id == report.id ? report : r;
    }).toList();
    state = state.copyWith(reports: updatedReports);
    
    // Attempt to submit update to backend via submitDvirReport for now (or a specific update endpoint if available)
    final result = await _repository.submitDvirReport(report);
    return result;
  }
}

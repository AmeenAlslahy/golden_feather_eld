import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../data/datasources/dvir_remote_data_source.dart';
import '../../data/repositories/dvir_repository_impl.dart';
import '../../domain/entities/dvir_report.dart';
import '../../domain/repositories/dvir_repository.dart';
import '../../../../core/services/tracking_config_storage_service.dart';

// --- Dependency Injection Providers ---

final dvirRemoteDataSourceProvider = Provider<DvirRemoteDataSource>((ref) {
  return DvirRemoteDataSourceImpl(
    apiClient: ref.watch(apiClientProvider),
    endpoints: ref.watch(endpointsProvider),
  );
});

final dvirRepositoryProvider = Provider<DvirRepository>((ref) {
  return DvirRepositoryImpl(
    remoteDataSource: ref.watch(dvirRemoteDataSourceProvider),
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
    final result = await _repository.getDvirReports(vehicleId.isEmpty ? 'unknown_vehicle' : vehicleId);
    
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
          final updatedReports = [report.copyWith(isSubmitted: true), ...state.reports];
          state = state.copyWith(
            isLoading: false,
            reports: updatedReports,
            error: null,
          );
        },
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/hos/domain/engine/diagnostics/diagnostics_engine.dart';
import '../../../../core/network/network_providers.dart';
import '../../domain/repositories/reports_repository.dart';
import '../../data/repositories/reports_repository_impl.dart';
import '../../../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../../../features/vehicle/presentation/providers/vehicle_provider.dart';

/// Reports Repository Provider
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final endpoints = ref.watch(endpointsProvider);
  return ReportsRepositoryImpl(apiClient, endpoints);
});

/// State for Reports
class ReportsState {
  final bool isLoading;
  final String? error;
  final DiagnosticsState diagnostics;

  final Map<String, dynamic>? eldReport;
  final Map<String, dynamic>? hosReport;
  
  // Standard Traccar Reports
  final List<dynamic>? standardSummary;
  final List<dynamic>? standardRoute;

  const ReportsState({
    this.eldReport,
    this.hosReport,
    this.standardSummary,
    this.standardRoute,
    this.isLoading = false,
    this.error,
    this.diagnostics = const DiagnosticsState(),
  });

  ReportsState copyWith({
    Map<String, dynamic>? eldReport,
    Map<String, dynamic>? hosReport,
    List<dynamic>? standardSummary,
    List<dynamic>? standardRoute,
    bool? isLoading,
    String? error,
    DiagnosticsState? diagnostics,
  }) {
    return ReportsState(
      eldReport: eldReport ?? this.eldReport,
      hosReport: hosReport ?? this.hosReport,
      standardSummary: standardSummary ?? this.standardSummary,
      standardRoute: standardRoute ?? this.standardRoute,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      diagnostics: diagnostics ?? this.diagnostics,
    );
  }
}

/// Reports Notifier
class ReportsNotifier extends StateNotifier<ReportsState> {
  final Ref _ref;

  ReportsNotifier(this._ref) : super(const ReportsState()) {
    _loadDiagnostics();
  }

  Future<void> generateReports() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = _ref.read(reportsRepositoryProvider);
      final backendType = _ref.read(backendTypeProvider);
      
      final authState = _ref.read(authStateProvider);
      final driverId = int.tryParse(authState.user?.id ?? '100') ?? 100;
      
      final vehicleState = _ref.read(vehicleProvider);
      final deviceIdStr = vehicleState.selectedVehicle?.id ?? '1';
      final deviceId = int.tryParse(deviceIdStr) ?? 1;
      final List<int> deviceIds = [deviceId];
      
      final now = DateTime.now().toUtc();
      final from = DateTime.utc(now.year, now.month, now.day).toIso8601String();
      final to = now.toIso8601String();

      if (backendType == 'traccar') {
        // Fetch standard Traccar reports
        final summaryResult = await repository.getSummaryReport(deviceIds, from, to);
        final routeResult = await repository.getRouteReport(deviceIds, from, to);
        
        List<dynamic>? summary;
        List<dynamic>? route;
        
        summaryResult.fold(
          (failure) => throw Exception(failure.message), 
          (data) => summary = data
        );
        
        routeResult.fold(
          (failure) => throw Exception(failure.message),
          (data) => route = data
        );
        
        state = state.copyWith(
          standardSummary: summary,
          standardRoute: route,
          isLoading: false,
        );
      } else {
        // Fetch ELD reports
        final eldResult = await repository.getComprehensiveEldReport(driverId);
        final hosResult = await repository.getHosReport(driverId);

        Map<String, dynamic>? eldReport;
        Map<String, dynamic>? hosReport;

        eldResult.fold(
          (failure) => throw Exception(failure.message),
          (data) => eldReport = data
        );

        hosResult.fold(
          (failure) => throw Exception(failure.message),
          (data) => hosReport = data
        );

        state = state.copyWith(
          eldReport: eldReport,
          hosReport: hosReport,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<String?> exportReport(bool isEld, String format, {String? standardReportType}) async {
    try {
      final repository = _ref.read(reportsRepositoryProvider);
      final backendType = _ref.read(backendTypeProvider);
      
      final authState = _ref.read(authStateProvider);
      final driverId = int.tryParse(authState.user?.id ?? '100') ?? 100;
      
      final vehicleState = _ref.read(vehicleProvider);
      final deviceIdStr = vehicleState.selectedVehicle?.id ?? '1';
      final deviceId = int.tryParse(deviceIdStr) ?? 1;
      final List<int> deviceIds = [deviceId];

      final now = DateTime.now().toUtc();
      final from = DateTime.utc(now.year, now.month, now.day).toIso8601String();
      final to = now.toIso8601String();

      if (backendType == 'traccar') {
        final result = await repository.exportStandardReport(standardReportType ?? 'summary', deviceIds, from, to);
        return result.fold((l) => null, (r) => r);
      } else {
        if (isEld) {
          final result = await repository.exportEldReport(driverId, format);
          return result.fold((l) => null, (r) => r);
        } else {
          final result = await repository.exportInspection(driverId, format);
          return result.fold((l) => null, (r) => r);
        }
      }
    } catch (e) {
      return null;
    }
  }

  void _loadDiagnostics() {
    final engine = _ref.read(diagnosticsEngineProvider);
    state = state.copyWith(diagnostics: engine.state);
  }

  void clearDiagnostics() {
    final engine = _ref.read(diagnosticsEngineProvider);
    engine.clearActive();
    _loadDiagnostics();
  }
}

/// Reports Provider
final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  return ReportsNotifier(ref);
});

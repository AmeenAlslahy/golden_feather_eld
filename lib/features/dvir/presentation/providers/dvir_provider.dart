import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/dvir_mock_data.dart';
import '../../domain/entities/dvir_report.dart';

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
  return DvirNotifier();
});

class DvirNotifier extends StateNotifier<DvirState> {
  DvirNotifier() : super(const DvirState()) {
    _loadDvirs();
  }

  Future<void> _loadDvirs() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final mockReports = DvirMockData.getDvirs();
      state = state.copyWith(isLoading: false, reports: mockReports);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load DVIRs: ${e.toString()}',
      );
    }
  }

  /// إنشاء تقرير جديد
  Future<void> createReport(DvirReport report) async {
    final updatedReports = [report, ...state.reports];
    state = state.copyWith(reports: updatedReports);
  }

  /// تحديث تقرير موجود
  void updateReport(DvirReport report) {
    final updatedReports = state.reports.map((r) {
      return r.id == report.id ? report : r;
    }).toList();
    state = state.copyWith(reports: updatedReports);
  }
}

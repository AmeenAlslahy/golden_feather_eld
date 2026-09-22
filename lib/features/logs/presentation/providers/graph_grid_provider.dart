/// Graph-Grid Provider — fetches official 24-hour graph data from API.
///
/// **API:** `GET /eld/daily-logs/{id}/graph-grid`
/// **SRS §5.2:** Official graph grid with segments, events, and totals.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_repository_providers.dart';
import '../../../../core/domain/shared/value_objects.dart';
import '../../domain/repositories/log_repository.dart';

/// State for the graph-grid data.
class GraphGridState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? data;

  // Parsed from API response
  final List<dynamic> segments;
  final List<dynamic> events;
  final Map<String, dynamic> totals;
  final bool hasGaps;

  const GraphGridState({
    this.isLoading = false,
    this.error,
    this.data,
    this.segments = const [],
    this.events = const [],
    this.totals = const {},
    this.hasGaps = false,
  });

  GraphGridState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    Map<String, dynamic>? data,
    List<dynamic>? segments,
    List<dynamic>? events,
    Map<String, dynamic>? totals,
    bool? hasGaps,
  }) {
    return GraphGridState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      data: data ?? this.data,
      segments: segments ?? this.segments,
      events: events ?? this.events,
      totals: totals ?? this.totals,
      hasGaps: hasGaps ?? this.hasGaps,
    );
  }

  // Convenience getters for totals
  String get formattedOffDuty =>
      totals['formattedOffDuty']?.toString() ?? '00:00';
  String get formattedSleeper =>
      totals['formattedSleeper']?.toString() ?? '00:00';
  String get formattedDriving =>
      totals['formattedDriving']?.toString() ?? '00:00';
  String get formattedOnDuty =>
      totals['formattedOnDuty']?.toString() ?? '00:00';
  String get formattedTotalAccounted =>
      totals['formattedTotalAccounted']?.toString() ?? '00:00';
}

/// Provider for graph-grid data.
final graphGridProvider =
    StateNotifierProvider<GraphGridNotifier, GraphGridState>((ref) {
  final repository = ref.watch(logRepositoryProvider);
  return GraphGridNotifier(repository);
});

class GraphGridNotifier extends StateNotifier<GraphGridState> {
  final LogRepository _repository;

  GraphGridNotifier(this._repository) : super(const GraphGridState());

  /// GET /eld/daily-logs/{id}/graph-grid
  Future<void> loadGraphGrid(DailyLogId logId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getGraphGrid(logId);

    if (!mounted) return;

    result.match(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (data) {
        final totalsMap = data['totals'] as Map<String, dynamic>? ?? {};
        state = state.copyWith(
          isLoading: false,
          data: data,
          segments: data['segments'] as List<dynamic>? ?? [],
          events: data['events'] as List<dynamic>? ?? [],
          totals: totalsMap,
          hasGaps: data['hasGaps'] as bool? ?? false,
        );
      },
    );
  }
}

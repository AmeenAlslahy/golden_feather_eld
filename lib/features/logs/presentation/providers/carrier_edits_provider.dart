/// Carrier Edits Provider — manages carrier-proposed edits.
///
/// **FMCSA §395.30(f):** Drivers can accept or reject carrier edits.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_repository_providers.dart';
import '../../../../core/domain/shared/value_objects.dart';
import '../../domain/repositories/log_repository.dart';

/// State for carrier edits.
class CarrierEditsState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> edits;

  // Response in progress
  final String? respondingEditId;
  final String? responseAction;

  const CarrierEditsState({
    this.isLoading = false,
    this.error,
    this.edits = const [],
    this.respondingEditId,
    this.responseAction,
  });

  CarrierEditsState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<Map<String, dynamic>>? edits,
    String? respondingEditId,
    String? responseAction,
  }) {
    return CarrierEditsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      edits: edits ?? this.edits,
      respondingEditId: respondingEditId,
      responseAction: responseAction,
    );
  }
}

/// Provider for carrier edits.
final carrierEditsProvider =
    StateNotifierProvider<CarrierEditsNotifier, CarrierEditsState>((ref) {
  final repository = ref.watch(logRepositoryProvider);
  return CarrierEditsNotifier(repository);
});

class CarrierEditsNotifier extends StateNotifier<CarrierEditsState> {
  final LogRepository _repository;

  CarrierEditsNotifier(this._repository) : super(const CarrierEditsState());

  /// Load carrier edits for a log.
  ///
  /// Note: Currently gets from getDailyLogById, which includes carrier edits.
  Future<void> loadEdits(DailyLogId logId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getDailyLogById(logId);

    if (!mounted) return;

    result.match(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (log) {
        // Extract carrier edits from log data
        // For now, we'll create mock edits since the DailyLog entity
        // doesn't have carrierEdits field yet
        state = state.copyWith(
          isLoading: false,
          edits: [], // Will be populated when API returns carrierEdits
        );
      },
    );
  }

  /// POST /eld/daily-logs/{logId}/carrier-edits/{editId}/respond
  Future<void> respondToEdit({
    required DailyLogId logId,
    required String editId,
    required String action,
    String? driverNotes,
  }) async {
    state = state.copyWith(
      respondingEditId: editId,
      responseAction: action,
      clearError: true,
    );

    final result = await _repository.respondToCarrierEdit(
      logId: logId,
      editId: editId,
      action: action,
      driverNotes: driverNotes,
    );

    if (!mounted) return;

    result.match(
      (failure) {
        state = state.copyWith(
          respondingEditId: null,
          responseAction: null,
          error: failure.message,
        );
      },
      (success) {
        // Update the edit status locally
        final updatedEdits = state.edits.map((edit) {
          if (edit['id']?.toString() == editId) {
            return {
              ...edit,
              'status': action == 'accept' ? 'accepted' : 'rejected',
              if (driverNotes != null && driverNotes.isNotEmpty)
                'driverNotes': driverNotes,
            };
          }
          return edit;
        }).toList();

        state = state.copyWith(
          respondingEditId: null,
          responseAction: null,
          edits: updatedEdits,
        );
      },
    );
  }
}

/// Form Tab Provider — connects to PUT /eld/daily-logs/{id}/form (Atomic Save).
///
/// **SRS §5.13 compliance:** All form elements (vehicles, trailers,
/// shipping documents, co-driver) are sent in a single atomic request.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_repository_providers.dart';
import '../../../../core/domain/shared/value_objects.dart';
import '../../domain/repositories/log_repository.dart';

/// State for the daily form.
class DailyFormState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final bool isSuccess;
  final Map<String, dynamic>? formData;

  // Local editing state (before save)
  final String? uniqueId;
  final int? coDriverId;
  final List<Map<String, String>> trailers;
  final List<Map<String, String>> shippingDocuments;
  final String? notes;

  const DailyFormState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.isSuccess = false,
    this.formData,
    this.uniqueId,
    this.coDriverId,
    this.trailers = const [],
    this.shippingDocuments = const [],
    this.notes,
  });

  DailyFormState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    bool? isSuccess,
    Map<String, dynamic>? formData,
    String? uniqueId,
    int? coDriverId,
    List<Map<String, String>>? trailers,
    List<Map<String, String>>? shippingDocuments,
    String? notes,
  }) {
    return DailyFormState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      isSuccess: isSuccess ?? this.isSuccess,
      formData: formData ?? this.formData,
      uniqueId: uniqueId ?? this.uniqueId,
      coDriverId: coDriverId ?? this.coDriverId,
      trailers: trailers ?? this.trailers,
      shippingDocuments: shippingDocuments ?? this.shippingDocuments,
      notes: notes ?? this.notes,
    );
  }

  /// Build the atomic request payload per SRS §5.13.
  Map<String, dynamic> toRequestPayload() {
    return {
      'uniqueId': uniqueId ?? '',
      'coDriverId': coDriverId,
      'trailers': trailers,
      'shippingDocuments': shippingDocuments,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

/// Provider for the daily form.
final dailyFormProvider =
    StateNotifierProvider<DailyFormNotifier, DailyFormState>((ref) {
  final repository = ref.watch(logRepositoryProvider);
  return DailyFormNotifier(repository);
});

class DailyFormNotifier extends StateNotifier<DailyFormState> {
  final LogRepository _repository;

  DailyFormNotifier(this._repository) : super(const DailyFormState());

  /// GET /eld/daily-logs/{id}/form — Load form data from API.
  Future<void> loadForm(DailyLogId logId) async {
    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);

    final result = await _repository.getForm(logId);

    if (!mounted) return;

    result.match(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (data) {
        // Parse API response into local state
        final trailers = (data['trailers'] as List<dynamic>?)
                ?.map((t) => {'trailerNumber': t.toString()})
                .toList() ??
            [];
        final docs = (data['shippingDocuments'] as List<dynamic>?)
                ?.map((d) => {'documentNumber': d.toString()})
                .toList() ??
            [];

        state = state.copyWith(
          isLoading: false,
          formData: data,
          uniqueId: data['uniqueId']?.toString(),
          coDriverId: data['coDriver']?['id'] as int?,
          trailers: trailers,
          shippingDocuments: docs,
          notes: data['notes']?.toString(),
        );
      },
    );
  }

  /// PUT /eld/daily-logs/{id}/form — Atomic save (SRS §5.13).
  ///
  /// Sends ALL form elements in ONE request:
  /// ```json
  /// {
  ///   "uniqueId": "...",
  ///   "coDriverId": 102,
  ///   "trailers": [{"trailerNumber": "3888"}],
  ///   "shippingDocuments": [{"documentNumber": "DOC-001"}],
  ///   "notes": "..."
  /// }
  /// ```
  Future<void> saveForm(DailyLogId logId) async {
    state = state.copyWith(isSaving: true, clearError: true, isSuccess: false);

    final payload = state.toRequestPayload();
    final result = await _repository.saveForm(
      logId: logId,
      formData: payload,
    );

    if (!mounted) return;

    result.match(
      (failure) {
        state = state.copyWith(isSaving: false, error: failure.message);
      },
      (data) {
        state = state.copyWith(
          isSaving: false,
          isSuccess: true,
          formData: data,
        );
      },
    );
  }

  // ========================================================================
  // Local editing methods (update state before save)
  // ========================================================================

  void setUniqueId(String? id) {
    state = state.copyWith(uniqueId: id);
  }

  void setCoDriverId(int? id) {
    state = state.copyWith(coDriverId: id);
  }

  void addTrailer(String trailerNumber) {
    if (trailerNumber.isEmpty) return;
    // Prevent duplicates
    if (state.trailers.any((t) => t['trailerNumber'] == trailerNumber)) return;
    state = state.copyWith(
      trailers: [...state.trailers, {'trailerNumber': trailerNumber}],
    );
  }

  void removeTrailer(String trailerNumber) {
    state = state.copyWith(
      trailers: state.trailers
          .where((t) => t['trailerNumber'] != trailerNumber)
          .toList(),
    );
  }

  void addShippingDocument(String documentNumber) {
    if (documentNumber.isEmpty) return;
    if (state.shippingDocuments
        .any((d) => d['documentNumber'] == documentNumber)) {
      return;
    }
    state = state.copyWith(
      shippingDocuments: [
        ...state.shippingDocuments,
        {'documentNumber': documentNumber}
      ],
    );
  }

  void removeShippingDocument(String documentNumber) {
    state = state.copyWith(
      shippingDocuments: state.shippingDocuments
          .where((d) => d['documentNumber'] != documentNumber)
          .toList(),
    );
  }

  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  void reset() {
    state = const DailyFormState();
  }
}

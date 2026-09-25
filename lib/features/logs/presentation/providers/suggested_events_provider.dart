import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The live contract has unidentified events, not a separate suggested-events API.
const suggestedEventsUnavailable =
    'Suggested events are not in the server contract. Use Unidentified Events.';

class SuggestedEventsState {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> items;

  const SuggestedEventsState({
    this.loading = false,
    this.error,
    this.items = const [],
  });
}

class SuggestedEventsNotifier extends StateNotifier<SuggestedEventsState> {
  SuggestedEventsNotifier() : super(const SuggestedEventsState());

  Future<void> load() async {
    state = const SuggestedEventsState(error: suggestedEventsUnavailable);
  }

  Future<String?> respond({
    required int id,
    required bool accept,
    required String annotation,
  }) async {
    return suggestedEventsUnavailable;
  }
}

final suggestedEventsProvider =
    StateNotifierProvider<SuggestedEventsNotifier, SuggestedEventsState>((ref) {
  return SuggestedEventsNotifier();
});

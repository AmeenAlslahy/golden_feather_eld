import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/contracts/contract_enums.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/error/app_error.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';


/// Reads the live list shape: a raw array, or an object containing that array.
/// Server rows are keyed by `statusId`, not a local id.
List<Map<String, dynamic>> parseUnidentifiedList(Map<String, dynamic> json) {
  final raw = json['items'] ?? json['events'] ?? json['content'] ?? json['data'];
  if (raw is! List) return const [];
  return raw.whereType<Map>().map(normalizeUnidentifiedItem).toList();
}

Map<String, dynamic> normalizeUnidentifiedItem(Map<dynamic, dynamic> raw) {
  final item = Map<String, dynamic>.from(raw);
  final statusId = item['statusId'];
  final parsedId = statusId is int
      ? statusId
      : int.tryParse('${statusId ?? ''}');
  return {
    'statusId': parsedId,
    'dutyStatus': '${item['status'] ?? item['dutyStatus'] ?? 'DRIVING'}',
    'startTime': item['startTime'],
    'endTime': item['endTime'],
    'formattedDuration': item['formattedDuration'],
    'location': item['locationText'] ?? item['location'] ?? item['locationDescription'] ?? '',
    'vehicleName': item['vehicleName'],
    'rejectionReason': item['rejectionReason'],
    'daysPending': item['daysPending'],
    'overdue': item['overdue'] == true,
  };
}

class UnidentifiedListState {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> items;

  const UnidentifiedListState({
    this.loading = false,
    this.error,
    this.items = const [],
  });

  UnidentifiedListState copyWith({
    bool? loading,
    String? error,
    List<Map<String, dynamic>>? items,
    bool clearError = false,
  }) {
    return UnidentifiedListState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      items: items ?? this.items,
    );
  }
}

class UnidentifiedEventsNotifier extends StateNotifier<UnidentifiedListState> {
  UnidentifiedEventsNotifier(this._ref) : super(const UnidentifiedListState());

  final Ref _ref;

  List<Map<String, dynamic>> _parse(Map<String, dynamic> json) =>
      parseUnidentifiedList(json);

  String _message(AppError error) {
    final message = error.context?['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();
    return 'The server did not accept this request.';
  }

  Future<void> load(UnidentifiedTab tab) async {
    state = state.copyWith(loading: true, clearError: true);
    final driverId = _ref.read(currentDriverIdProvider);
    final result = await _ref.read(unidentifiedEventsBackendProvider).list(
          tab: tab,
          driverId: driverId == null ? null : DriverId(driverId),
        );
    result.fold(
      (error) {
        state = UnidentifiedListState(
          loading: false,
          error: _message(error),
          items: const [],
        );
      },
      (json) {
        state = UnidentifiedListState(
          loading: false,
          items: _parse(json),
        );
      },
    );
  }

  Future<String?> claim(int id, String annotation) async {
    final driverId = _ref.read(currentDriverIdProvider);
    if (driverId == null) return 'Driver session is missing.';
    if (annotation.trim().isEmpty) return 'An annotation is required.';
    final result = await _ref.read(unidentifiedEventsBackendProvider).claim(
          id: DutyStatusId(id),
          driverId: DriverId(driverId),
          annotation: annotation.trim(),
        );
    return result.fold(_message, (_) => null);
  }

  Future<String?> reject(int id, String reason) async {
    final driverId = _ref.read(currentDriverIdProvider);
    if (driverId == null) return 'Driver session is missing.';
    if (reason.trim().isEmpty) return 'A rejection reason is required.';
    final result = await _ref.read(unidentifiedEventsBackendProvider).reject(
          id: DutyStatusId(id),
          driverId: DriverId(driverId),
          rejectionReason: reason.trim(),
        );
    return result.fold(_message, (_) => null);
  }
}

final unidentifiedEventsProvider = StateNotifierProvider<
    UnidentifiedEventsNotifier, UnidentifiedListState>((ref) {
  return UnidentifiedEventsNotifier(ref);
});

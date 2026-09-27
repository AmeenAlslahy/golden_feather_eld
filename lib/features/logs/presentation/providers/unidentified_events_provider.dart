import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/contracts/contract_enums.dart';
import '../../../../core/error/app_error.dart';
import '../../../../backend/providers/backend_providers.dart';
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
    'uniqueId': item['uniqueId'],
    'allocationStatus': item['allocationStatus'],
    'rejectionReason': item['rejectionReason'],
    'daysPending': item['daysPending'],
    'overdue': item['overdue'] == true,
  };
}

class UnidentifiedListState {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> items;

  /// SRS 11.2 counters — size of the *other* tab, fetched alongside the
  /// current one so TOTAL / UNCLAIMED / REJECTED are real, not "—".
  /// `null` when that count could not be fetched.
  final int? unclaimedCount;
  final int? rejectedCount;

  const UnidentifiedListState({
    this.loading = false,
    this.error,
    this.items = const [],
    this.unclaimedCount,
    this.rejectedCount,
  });

  UnidentifiedListState copyWith({
    bool? loading,
    String? error,
    List<Map<String, dynamic>>? items,
    int? unclaimedCount,
    int? rejectedCount,
    bool clearError = false,
  }) {
    return UnidentifiedListState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      items: items ?? this.items,
      unclaimedCount: unclaimedCount ?? this.unclaimedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
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

  /// [uniqueId] — SRS 11.2 vehicle filter, passed through to the server
  /// (`GET /eld/unidentified-events?uniqueId=`); null = all vehicles.
  Future<void> load(UnidentifiedTab tab, {String? uniqueId}) async {
    state = state.copyWith(loading: true, clearError: true);
    final driverId = _ref.read(currentDriverIdProvider);
    final backend = _ref.read(unidentifiedEventsBackendProvider);
    final driver = driverId == null ? null : DriverId(driverId);
    final other = tab == UnidentifiedTab.unclaimed
        ? UnidentifiedTab.rejected
        : UnidentifiedTab.unclaimed;
    final results = await Future.wait([
      backend.list(tab: tab, uniqueId: uniqueId, driverId: driver),
      backend.list(tab: other, uniqueId: uniqueId, driverId: driver),
    ]);
    final otherCount =
        results[1].fold<int?>((_) => null, (json) => _parse(json).length);
    results[0].fold(
      (error) {
        state = UnidentifiedListState(
          loading: false,
          error: _message(error),
          items: const [],
        );
      },
      (json) {
        final items = _parse(json);
        final unclaimed =
            tab == UnidentifiedTab.unclaimed ? items.length : otherCount;
        final rejected =
            tab == UnidentifiedTab.rejected ? items.length : otherCount;
        state = UnidentifiedListState(
          loading: false,
          items: items,
          unclaimedCount: unclaimed,
          rejectedCount: rejected,
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

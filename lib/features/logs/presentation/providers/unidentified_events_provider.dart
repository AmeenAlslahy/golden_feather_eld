import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/contracts/contract_enums.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/events/app_events.dart';
import '../../../../core/time/time_authority_provider.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../../vehicle/domain/vehicle_selection.dart';
import '../../../vehicle/presentation/providers/vehicle_provider.dart';

/// Reads the live list shape: a raw array, or an object containing that array.
/// Server rows are keyed by `statusId`, not a local id.
List<Map<String, dynamic>> parseUnidentifiedList(Map<String, dynamic> json) {
  final raw =
      json['items'] ?? json['events'] ?? json['content'] ?? json['data'];
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
    'durationMinutes': item['durationMinutes'],
    'formattedDuration': item['formattedDuration'],
    'startOdometerKm': item['startOdometerKm'],
    'endOdometerKm': item['endOdometerKm'],
    'totalDistanceKm': item['totalDistanceKm'],
    'createdAt': item['createdAt'],
    'location':
        item['locationText'] ??
        item['location'] ??
        item['locationDescription'] ??
        '',
    'vehicleName': item['vehicleName'],
    'uniqueId': item['uniqueId'],
    'allocationStatus': item['allocationStatus'],
    'rejectionReason': item['rejectionReason'],
    'daysPending': item['daysPending'],
    'overdue': item['overdue'] == true,
  };
}

/// نموذج بيانات موثوق ومفصل للحدث غير المحدد
class UnidentifiedEventItem {
  final int? statusId;
  final String dutyStatus;
  final String startTime;
  final String endTime;
  final int? durationMinutes;
  final String formattedDuration;
  final num? startOdometerKm;
  final num? endOdometerKm;
  final num? totalDistanceKm;
  final String createdAt;
  final String location;
  final String vehicleName;
  final String uniqueId;
  final String allocationStatus;
  final String rejectionReason;
  final int? daysPending;
  final bool overdue;

  const UnidentifiedEventItem({
    this.statusId,
    this.dutyStatus = 'DRIVING',
    this.startTime = '',
    this.endTime = '',
    this.durationMinutes,
    this.formattedDuration = '',
    this.startOdometerKm,
    this.endOdometerKm,
    this.totalDistanceKm,
    this.createdAt = '',
    this.location = '',
    this.vehicleName = '',
    this.uniqueId = '',
    this.allocationStatus = '',
    this.rejectionReason = '',
    this.daysPending,
    this.overdue = false,
  });

  factory UnidentifiedEventItem.fromMap(Map<String, dynamic> item) {
    return UnidentifiedEventItem(
      statusId: item['statusId'] is int ? item['statusId'] as int : null,
      dutyStatus: '${item['dutyStatus'] ?? 'DRIVING'}',
      startTime: '${item['startTime'] ?? ''}',
      endTime: '${item['endTime'] ?? ''}',
      durationMinutes: _asInt(item['durationMinutes']),
      formattedDuration: '${item['formattedDuration'] ?? ''}',
      startOdometerKm: _asNum(item['startOdometerKm']),
      endOdometerKm: _asNum(item['endOdometerKm']),
      totalDistanceKm: _asNum(item['totalDistanceKm']),
      createdAt: '${item['createdAt'] ?? ''}',
      location: '${item['location'] ?? ''}',
      vehicleName: '${item['vehicleName'] ?? ''}',
      uniqueId: '${item['uniqueId'] ?? ''}',
      allocationStatus: '${item['allocationStatus'] ?? ''}',
      rejectionReason: '${item['rejectionReason'] ?? ''}',
      daysPending: item['daysPending'] is int
          ? item['daysPending'] as int
          : null,
      overdue: item['overdue'] == true,
    );
  }
}

int? _asInt(Object? value) => value is int ? value : int.tryParse('$value');

num? _asNum(Object? value) {
  if (value is num) return value;
  return num.tryParse('$value');
}

/// نتائج إحصائيات الأحداث غير المحددة (SRS 11.2 & SRS 11.6)
class UnidentifiedStats {
  final int total;
  final String unclaimed;
  final String rejected;
  final int driving24h;

  const UnidentifiedStats({
    required this.total,
    required this.unclaimed,
    required this.rejected,
    required this.driving24h,
  });
}

class UnidentifiedListState {
  final bool loading;
  final String? error;
  final List<UnidentifiedEventItem> allEvents;
  final List<UnidentifiedEventItem> items;
  final UnidentifiedTab tab;
  final bool currentVehicleOnly;
  final String? vehicleUniqueId;
  final DateTime? dateFilter;
  final int? unclaimedCount;
  final int? rejectedCount;
  final UnidentifiedStats stats;

  const UnidentifiedListState({
    this.loading = false,
    this.error,
    this.allEvents = const [],
    this.items = const [],
    this.tab = UnidentifiedTab.unclaimed,
    this.currentVehicleOnly = false,
    this.vehicleUniqueId,
    this.dateFilter,
    this.unclaimedCount,
    this.rejectedCount,
    this.stats = const UnidentifiedStats(
      total: 0,
      unclaimed: '0',
      rejected: '0',
      driving24h: 0,
    ),
  });

  bool get hasFilters => currentVehicleOnly || dateFilter != null;

  UnidentifiedListState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    List<UnidentifiedEventItem>? allEvents,
    List<UnidentifiedEventItem>? items,
    UnidentifiedTab? tab,
    bool? currentVehicleOnly,
    String? vehicleUniqueId,
    bool clearVehicle = false,
    DateTime? dateFilter,
    bool clearDateFilter = false,
    int? unclaimedCount,
    int? rejectedCount,
    UnidentifiedStats? stats,
  }) {
    return UnidentifiedListState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      allEvents: allEvents ?? this.allEvents,
      items: items ?? this.items,
      tab: tab ?? this.tab,
      currentVehicleOnly: currentVehicleOnly ?? this.currentVehicleOnly,
      vehicleUniqueId: clearVehicle
          ? null
          : (vehicleUniqueId ?? this.vehicleUniqueId),
      dateFilter: clearDateFilter ? null : (dateFilter ?? this.dateFilter),
      unclaimedCount: unclaimedCount ?? this.unclaimedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
      stats: stats ?? this.stats,
    );
  }
}

class UnidentifiedEventsNotifier extends StateNotifier<UnidentifiedListState> {
  UnidentifiedEventsNotifier(this.ref) : super(const UnidentifiedListState());

  final Ref ref;

  List<Map<String, dynamic>> _parse(Map<String, dynamic> json) =>
      parseUnidentifiedList(json);

  String _message(AppError error) {
    final message = error.context?['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();
    return 'The server did not accept this request.';
  }

  Future<String?> _resolveVehicleUniqueId() async {
    var vehicleState = ref.read(vehicleProvider);
    if (vehicleState.selectedVehicle == null && !vehicleState.isInitialized) {
      await ref.read(vehicleProvider.notifier).loadVehicles();
      vehicleState = ref.read(vehicleProvider);
    }
    final vehicle = vehicleState.selectedVehicle;
    // Vehicle selection already accepts `vehicle.id` when the API omits
    // `uniqueId`; the unidentified-events endpoint accepts the device/vehicle
    // identifier in the same query field. Use that selected identifier before
    // falling back to the dashboard's owner-scoped current selection.
    return readOperableUniqueId(vehicle?.uniqueId) ??
        readOperableUniqueId(vehicle?.id) ??
        readOperableUniqueId(ref.read(dashboardDataProvider).vehicleId);
  }

  /// [uniqueId] — SRS 11.2 vehicle filter, passed through to the server
  /// (`GET /eld/unidentified-events?uniqueId=`); null = all vehicles.
  Future<void> load({UnidentifiedTab? tab, String? uniqueId}) async {
    final activeTab = tab ?? state.tab;
    final vehicleFilter =
        uniqueId ?? (state.currentVehicleOnly ? state.vehicleUniqueId : null);

    state = state.copyWith(loading: true, clearError: true, tab: activeTab);
    final driverId = ref.read(currentDriverIdProvider);
    final backend = ref.read(unidentifiedEventsBackendProvider);
    final driver = driverId == null ? null : DriverId(driverId);
    final other = activeTab == UnidentifiedTab.unclaimed
        ? UnidentifiedTab.rejected
        : UnidentifiedTab.unclaimed;

    final results = await Future.wait([
      backend.list(tab: activeTab, uniqueId: vehicleFilter, driverId: driver),
      backend.list(tab: other, uniqueId: vehicleFilter, driverId: driver),
    ]);

    final otherCount = results[1].fold<int?>(
      (_) => null,
      (json) => _parse(json).length,
    );

    results[0].fold(
      (error) {
        state = state.copyWith(
          loading: false,
          error: _message(error),
          allEvents: const [],
          items: const [],
          stats: const UnidentifiedStats(
            total: 0,
            unclaimed: '0',
            rejected: '0',
            driving24h: 0,
          ),
        );
      },
      (json) {
        final rawMaps = _parse(json);
        final events = rawMaps.map(UnidentifiedEventItem.fromMap).toList();
        final unclaimed = activeTab == UnidentifiedTab.unclaimed
            ? events.length
            : otherCount;
        final rejected = activeTab == UnidentifiedTab.rejected
            ? events.length
            : otherCount;

        final filtered = _filterByDate(events, state.dateFilter);
        final now = ref.read(timeAuthorityProvider).nowUtc();
        final stats = _computeStats(
          items: filtered,
          tab: activeTab,
          now: now,
          unclaimedCount: unclaimed,
          rejectedCount: rejected,
        );

        state = state.copyWith(
          loading: false,
          allEvents: events,
          items: filtered,
          unclaimedCount: unclaimed,
          rejectedCount: rejected,
          stats: stats,
        );
      },
    );
  }

  List<UnidentifiedEventItem> _filterByDate(
    List<UnidentifiedEventItem> events,
    DateTime? day,
  ) {
    if (day == null) return events;
    return events.where((item) {
      final raw = item.startTime;
      final when = raw.isEmpty ? null : DateTime.tryParse(raw)?.toLocal();
      return when != null &&
          when.year == day.year &&
          when.month == day.month &&
          when.day == day.day;
    }).toList();
  }

  UnidentifiedStats _computeStats({
    required List<UnidentifiedEventItem> items,
    required UnidentifiedTab tab,
    required DateTime now,
    int? unclaimedCount,
    int? rejectedCount,
  }) {
    final since = now.subtract(const Duration(hours: 24));
    final driving = items.where((item) {
      final status = item.dutyStatus.toUpperCase();
      if (!status.contains('DRIV')) return false;
      final raw = item.endTime.isNotEmpty ? item.endTime : item.startTime;
      final when = raw.isEmpty ? null : DateTime.tryParse(raw);
      return when == null || !when.toUtc().isBefore(since);
    }).length;

    final unclaimed = tab == UnidentifiedTab.unclaimed
        ? items.length
        : unclaimedCount;
    final rejected = tab == UnidentifiedTab.rejected
        ? items.length
        : rejectedCount;
    final total = (unclaimed == null || rejected == null)
        ? items.length
        : unclaimed + rejected;

    return UnidentifiedStats(
      total: total,
      unclaimed: unclaimed != null ? '$unclaimed' : '—',
      rejected: rejected != null ? '$rejected' : '—',
      driving24h: driving,
    );
  }

  Future<void> setTab(UnidentifiedTab tab) async {
    if (state.tab == tab && !state.loading) return;
    await load(tab: tab);
  }

  Future<bool> toggleVehicleFilter() async {
    final turningOn = !state.currentVehicleOnly;
    if (turningOn) {
      final uid = await _resolveVehicleUniqueId();
      if (uid == null) {
        return false;
      }
      state = state.copyWith(currentVehicleOnly: true, vehicleUniqueId: uid);
    } else {
      state = state.copyWith(currentVehicleOnly: false, clearVehicle: true);
    }
    await load();
    return true;
  }

  void setDateFilter(DateTime? date) {
    state = state.copyWith(dateFilter: date, clearDateFilter: date == null);
    final filtered = _filterByDate(state.allEvents, state.dateFilter);
    final now = ref.read(timeAuthorityProvider).nowUtc();
    final stats = _computeStats(
      items: filtered,
      tab: state.tab,
      now: now,
      unclaimedCount: state.unclaimedCount,
      rejectedCount: state.rejectedCount,
    );
    state = state.copyWith(items: filtered, stats: stats);
  }

  void clearFilters() {
    state = state.copyWith(
      currentVehicleOnly: false,
      clearVehicle: true,
      clearDateFilter: true,
    );
    load();
  }

  void refresh() {
    load();
  }

  Future<Failure?> claim(int id, String annotation) async {
    final driverId = ref.read(currentDriverIdProvider);
    if (driverId == null) {
      return const ServerFailure(message: 'Driver session is missing.');
    }
    if (annotation.trim().isEmpty) {
      return const ServerFailure(message: 'An annotation is required.');
    }
    final result = await ref
        .read(unidentifiedEventsBackendProvider)
        .claim(
          id: DutyStatusId(id),
          driverId: DriverId(driverId),
          annotation: annotation.trim(),
        );
    return await result.fold<Future<Failure?>>(
      (e) async => ServerFailure(message: _message(e)),
      (_) async {
        _refreshDependencies();
        await load();
        return null;
      },
    );
  }

  Future<Failure?> reject(int id, String reason) async {
    final driverId = ref.read(currentDriverIdProvider);
    if (driverId == null) {
      return const ServerFailure(message: 'Driver session is missing.');
    }
    if (reason.trim().isEmpty) {
      return const ServerFailure(message: 'A rejection reason is required.');
    }
    final result = await ref
        .read(unidentifiedEventsBackendProvider)
        .reject(
          id: DutyStatusId(id),
          driverId: DriverId(driverId),
          rejectionReason: reason.trim(),
        );
    return await result.fold<Future<Failure?>>(
      (e) async => ServerFailure(message: _message(e)),
      (_) async {
        _refreshDependencies();
        await load();
        return null;
      },
    );
  }

  void _refreshDependencies() {
    ref.read(appEventBusProvider).fire(AppEvent.logDataChanged);
  }
}

final unidentifiedEventsProvider =
    StateNotifierProvider<UnidentifiedEventsNotifier, UnidentifiedListState>((
      ref,
    ) {
      return UnidentifiedEventsNotifier(ref);
    });

/// حساب إحصائيات الأحداث غير المحددة (دالة مساعدة للتوافقية)
UnidentifiedStats calculateUnidentifiedStats({
  required List<dynamic> items,
  required UnidentifiedTab tab,
  required DateTime now,
  int? unclaimedCount,
  int? rejectedCount,
}) {
  final eventItems = items.map((e) {
    if (e is UnidentifiedEventItem) return e;
    if (e is Map) {
      return UnidentifiedEventItem.fromMap(Map<String, dynamic>.from(e));
    }
    return const UnidentifiedEventItem();
  }).toList();

  final since = now.subtract(const Duration(hours: 24));
  final driving = eventItems.where((item) {
    final status = item.dutyStatus.toUpperCase();
    if (!status.contains('DRIV')) return false;
    final raw = item.endTime.isNotEmpty ? item.endTime : item.startTime;
    final when = raw.isEmpty ? null : DateTime.tryParse(raw);
    return when == null || !when.toUtc().isBefore(since);
  }).length;

  final unclaimed = tab == UnidentifiedTab.unclaimed
      ? eventItems.length
      : unclaimedCount;
  final rejected = tab == UnidentifiedTab.rejected
      ? eventItems.length
      : rejectedCount;
  final total = (unclaimed == null || rejected == null)
      ? eventItems.length
      : unclaimed + rejected;

  return UnidentifiedStats(
    total: total,
    unclaimed: unclaimed != null ? '$unclaimed' : '—',
    rejected: rejected != null ? '$rejected' : '—',
    driving24h: driving,
  );
}

/// تصفية الأحداث بالتاريخ محلياً (دالة مساعدة للتوافقية)
List<T> filterUnidentifiedEventsByDate<T>(List<T> items, DateTime? day) {
  if (day == null) return items;
  return items.where((item) {
    final String raw;
    if (item is UnidentifiedEventItem) {
      raw = item.startTime;
    } else if (item is Map) {
      raw = '${item['startTime'] ?? ''}';
    } else {
      return false;
    }
    final when = raw.isEmpty ? null : DateTime.tryParse(raw)?.toLocal();
    return when != null &&
        when.year == day.year &&
        when.month == day.month &&
        when.day == day.day;
  }).toList();
}

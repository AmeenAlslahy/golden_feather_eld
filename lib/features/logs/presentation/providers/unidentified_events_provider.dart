import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/events/app_events.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../vehicle/presentation/providers/vehicle_provider.dart';
import '../../data/providers/unidentified_events_repository_provider.dart';
import '../../domain/entities/unidentified_event.dart';
import '../../domain/services/unidentified_events.dart';

export '../../domain/entities/unidentified_event.dart';

class UnidentifiedListState {
  final bool loading;
  final String? error;
  final List<UnidentifiedEvent> allEvents;
  final List<UnidentifiedEvent> items;
  final UnidentifiedTab tab;
  final bool currentVehicleOnly;
  final int? vehicleDeviceId;
  final String? vehicleVin;
  final String? vehicleName;
  final DateTime? dateFilter;
  final UnidentifiedStats stats;
  final String? lastSuccessMessage;

  const UnidentifiedListState({
    this.loading = false,
    this.error,
    this.allEvents = const [],
    this.items = const [],
    this.tab = UnidentifiedTab.unclaimed,
    this.currentVehicleOnly = false,
    this.vehicleDeviceId,
    this.vehicleVin,
    this.vehicleName,
    this.dateFilter,
    this.stats = UnidentifiedStats.unavailable,
    this.lastSuccessMessage,
  });

  bool get hasFilters => currentVehicleOnly || dateFilter != null;

  UnidentifiedListState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    List<UnidentifiedEvent>? allEvents,
    List<UnidentifiedEvent>? items,
    UnidentifiedTab? tab,
    bool? currentVehicleOnly,
    int? vehicleDeviceId,
    String? vehicleVin,
    String? vehicleName,
    bool clearVehicle = false,
    DateTime? dateFilter,
    bool clearDateFilter = false,
    UnidentifiedStats? stats,
    String? lastSuccessMessage,
  }) {
    return UnidentifiedListState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      allEvents: allEvents ?? this.allEvents,
      items: items ?? this.items,
      tab: tab ?? this.tab,
      currentVehicleOnly: currentVehicleOnly ?? this.currentVehicleOnly,
      vehicleDeviceId: clearVehicle
          ? null
          : (vehicleDeviceId ?? this.vehicleDeviceId),
      vehicleVin: clearVehicle ? null : (vehicleVin ?? this.vehicleVin),
      vehicleName: clearVehicle ? null : (vehicleName ?? this.vehicleName),
      dateFilter: clearDateFilter ? null : (dateFilter ?? this.dateFilter),
      stats: stats ?? this.stats,
      lastSuccessMessage: lastSuccessMessage ?? this.lastSuccessMessage,
    );
  }
}

class UnidentifiedEventsNotifier extends StateNotifier<UnidentifiedListState> {
  UnidentifiedEventsNotifier(this.ref) : super(const UnidentifiedListState());

  /// The documented maximum for `size`; the list has no paging UI yet.
  static const int _pageSize = 100;

  final Ref ref;

  String _message(Failure failure) => anyErrorUserMessage(
    failure,
    loc: lookupAppLocalizations(ref.read(localeProvider)),
  );

  Future<_VehicleFilter?> _resolveVehicleFilter() async {
    var vehicleState = ref.read(vehicleProvider);
    if (vehicleState.selectedVehicle == null && !vehicleState.isInitialized) {
      await ref.read(vehicleProvider.notifier).loadVehicles();
      vehicleState = ref.read(vehicleProvider);
    }
    final vehicle = vehicleState.selectedVehicle;
    if (vehicle == null) return null;

    final deviceId = vehicle.deviceId;
    final vin = vehicle.vin?.trim();
    final name = vehicle.name.trim();
    if (deviceId == null && (vin == null || vin.isEmpty) && name.isEmpty) {
      return null;
    }
    return _VehicleFilter(deviceId: deviceId, vin: vin, vehicleName: name);
  }

  /// Loads the active tab and the server summary.
  ///
  /// The summary endpoint has no filters, so the counters are the
  /// driver-scoped server totals. The vehicle and date filters narrow the
  /// visible list only.
  Future<void> load({UnidentifiedTab? tab}) async {
    final activeTab = tab ?? state.tab;
    state = state.copyWith(loading: true, clearError: true, tab: activeTab);

    final repository = ref.read(unidentifiedEventsRepositoryProvider);
    final eventsFuture = repository.getEvents(
      tab: activeTab,
      page: 0,
      size: _pageSize,
    );
    final summaryFuture = repository.getSummary();

    final eventsResult = await eventsFuture;
    final summaryResult = await summaryFuture;
    if (!mounted) return;

    final summary = summaryResult.fold<UnidentifiedSummary?>(
      (_) => null,
      (value) => value,
    );

    eventsResult.fold(
      (failure) {
        state = state.copyWith(
          loading: false,
          error: _message(failure),
          allEvents: const [],
          items: const [],
          stats: statsFromSummary(summary),
        );
      },
      (events) {
        state = state.copyWith(
          loading: false,
          allEvents: events,
          items: _applyFilters(events),
          stats: statsFromSummary(summary),
        );
      },
    );
  }

  Future<void> setTab(UnidentifiedTab tab) async {
    if (state.tab == tab && !state.loading) return;
    await load(tab: tab);
  }

  Future<bool> toggleVehicleFilter() async {
    final turningOn = !state.currentVehicleOnly;
    if (turningOn) {
      final filter = await _resolveVehicleFilter();
      if (filter == null) return false;
      state = state.copyWith(currentVehicleOnly: true, clearVehicle: true);
      state = state.copyWith(
        vehicleDeviceId: filter.deviceId,
        vehicleVin: filter.vin,
        vehicleName: filter.vehicleName,
      );
    } else {
      state = state.copyWith(currentVehicleOnly: false, clearVehicle: true);
    }
    await load();
    return true;
  }

  void setDateFilter(DateTime? date) {
    state = state.copyWith(dateFilter: date, clearDateFilter: date == null);
    state = state.copyWith(items: _applyFilters(state.allEvents));
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
    final normalized = annotation.trim();
    if (normalized.length < 4 || normalized.length > 500) {
      return const ServerFailure(
        message: 'Annotation must be between 4 and 500 characters.',
      );
    }
    final result = await ref
        .read(unidentifiedEventsRepositoryProvider)
        .claim(
          id: DutyStatusId(id),
          driverId: DriverId(driverId),
          annotation: normalized,
        );
    return result.fold<Future<Failure?>>((failure) async => failure, (_) async {
      final msg =
          ref.read(unidentifiedEventsRepositoryProvider).lastServerMessage;
      state = state.copyWith(lastSuccessMessage: msg);
      _refreshDependencies();
      await load();
      return null;
    });
  }

  Future<Failure?> reject(int id, String reason) async {
    final driverId = ref.read(currentDriverIdProvider);
    if (driverId == null) {
      return const ServerFailure(message: 'Driver session is missing.');
    }
    final normalized = reason.trim();
    if (normalized.length < 4 || normalized.length > 500) {
      return const ServerFailure(
        message: 'Rejection reason must be between 4 and 500 characters.',
      );
    }
    final result = await ref
        .read(unidentifiedEventsRepositoryProvider)
        .reject(
          id: DutyStatusId(id),
          driverId: DriverId(driverId),
          rejectionReason: normalized,
        );
    return result.fold<Future<Failure?>>((failure) async => failure, (_) async {
      final msg =
          ref.read(unidentifiedEventsRepositoryProvider).lastServerMessage;
      state = state.copyWith(lastSuccessMessage: msg);
      _refreshDependencies();
      await load();
      return null;
    });
  }

  List<UnidentifiedEvent> _applyFilters(List<UnidentifiedEvent> events) {
    final byVehicle = filterUnidentifiedEventsByVehicle(
      events,
      deviceId: state.vehicleDeviceId,
      vin: state.vehicleVin,
      vehicleName: state.vehicleName,
    );
    return filterUnidentifiedEventsByDate(byVehicle, state.dateFilter);
  }

  void _refreshDependencies() {
    ref.read(appEventBusProvider).fire(AppEvent.logDataChanged);
  }
}

class _VehicleFilter {
  final int? deviceId;
  final String? vin;
  final String? vehicleName;

  const _VehicleFilter({this.deviceId, this.vin, this.vehicleName});
}

final unidentifiedEventsProvider =
    StateNotifierProvider.autoDispose<
      UnidentifiedEventsNotifier,
      UnidentifiedListState
    >((ref) {
      return UnidentifiedEventsNotifier(ref);
    });

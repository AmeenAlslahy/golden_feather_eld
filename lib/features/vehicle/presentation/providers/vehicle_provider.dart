import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/vehicle_repository_providers.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../../domain/entities/vehicle.dart';

/// حالة شاشة المركبات
class VehicleState {
  final List<Vehicle> vehicles;
  final Vehicle? selectedVehicle;
  final String searchQuery;
  final bool isLoading;
  final String? error;
  final bool isInitialized;
  final bool isSuccess;

  const VehicleState({
    this.vehicles = const [],
    this.selectedVehicle,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
    this.isSuccess = false,
  });

  List<Vehicle> get filteredVehicles {
    if (searchQuery.isEmpty) return vehicles;
    return vehicles.where((v) {
      final query = searchQuery.toLowerCase();
      return v.id.contains(query) ||
          v.name.toLowerCase().contains(query) ||
          v.year.contains(query);
    }).toList();
  }

  VehicleState copyWith({
    List<Vehicle>? vehicles,
    Vehicle? selectedVehicle,
    bool clearSelected = false,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool? isSuccess,
  }) {
    return VehicleState(
      vehicles: vehicles ?? this.vehicles,
      selectedVehicle: clearSelected
          ? selectedVehicle
          : (selectedVehicle ?? this.selectedVehicle),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Can be null to clear error
      isInitialized: isInitialized ?? this.isInitialized,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// مزود المركبات
final vehicleProvider =
    StateNotifierProvider<VehicleNotifier, VehicleState>((ref) {
  return VehicleNotifier(
    ref.watch(vehicleRepositoryProvider),
  );
});

class VehicleNotifier extends StateNotifier<VehicleState> {
  final VehicleRepository _repository;

  VehicleNotifier(this._repository) : super(const VehicleState()) {
    loadVehicles();
  }

  Future<void> loadVehicles({bool forceRefresh = false}) async {
    if (state.isInitialized && !forceRefresh) return;

    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    final result = await _repository.getVehicles();

    result.match((failure) {
      state = state.copyWith(
        isLoading: false,
        error: failure.message,
      );
    }, (vehicles) {
      final selected = _serverSelected(vehicles);
      state = state.copyWith(
        vehicles: vehicles,
        selectedVehicle: selected,
        clearSelected: selected == null,
        isLoading: false,
        isInitialized: true,
        error: null,
      );
    });
  }

  Future<void> loadCompanyVehicles() async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    final result = await _repository.getCompanyVehicles();
    result.match((failure) {
      state = state.copyWith(isLoading: false, error: failure.message);
    }, (vehicles) {
      state = state.copyWith(
        vehicles: vehicles,
        isLoading: false,
        isInitialized: true,
        error: null,
      );
    });
  }

  Vehicle? _serverSelected(List<Vehicle> vehicles) {
    for (final vehicle in vehicles) {
      if (vehicle.activeForCurrentDriver == true ||
          vehicle.selectedByServer == true) {
        return vehicle;
      }
    }
    return null;
  }

  /// البحث عن مركبة
  void search(String query) {
    state = state.copyWith(searchQuery: query, error: state.error);
  }

  /// اختيار مركبة
  Future<void> selectVehicle(
    Vehicle vehicle, {
    required double? speedMps,
    required double thresholdKmh,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    // List tap is select, not operate. Connection page owns connectSession.
    state = state.copyWith(
      isLoading: false,
      selectedVehicle: vehicle,
      isSuccess: true,
      error: null,
    );
  }
}

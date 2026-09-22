import 'package:flutter_riverpod/flutter_riverpod.dart';

// ARCH-HIGH-01 fix: Import from composition root, not data/repositories directly
import '../../../../app/providers/app_repository_providers.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';

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
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool? isSuccess,
  }) {
    return VehicleState(
      vehicles: vehicles ?? this.vehicles,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Can be null to clear error
      isInitialized: isInitialized ?? this.isInitialized,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// مزود المركبات (uses vehicleRepositoryProvider from composition root)
final vehicleProvider =
    StateNotifierProvider<VehicleNotifier, VehicleState>((ref) {
  return VehicleNotifier(
    ref.watch(vehicleRepositoryProvider),
  );
});

class VehicleNotifier extends StateNotifier<VehicleState> {
  final VehicleRepository _repository;

  VehicleNotifier(this._repository) : super(const VehicleState()) {
    _init();
  }

  Future<void> _init() async {
    await _loadSelectedVehicle();
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
      state = state.copyWith(
        vehicles: vehicles,
        isLoading: false,
        isInitialized: true,
      );
    });
  }

  Future<void> _loadSelectedVehicle() async {
    final result = await _repository.getSelectedVehicle();
    result.match((failure) {}, (vehicle) {
      if (vehicle != null) {
        state = state.copyWith(selectedVehicle: vehicle);
      }
    });
  }

  /// البحث عن مركبة
  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// اختيار مركبة
  Future<void> selectVehicle(Vehicle vehicle) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    final result = await _repository.selectVehicle(vehicle.id);

    result.match((failure) {
      state = state.copyWith(isLoading: false, error: failure.message);
    }, (_) {
      state = state.copyWith(
        isLoading: false,
        selectedVehicle: vehicle,
        isSuccess: true,
      );
    });
  }
}

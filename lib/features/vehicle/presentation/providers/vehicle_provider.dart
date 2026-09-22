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
    final query = searchQuery.toLowerCase();
    return vehicles.where((v) {
      return v.id.toLowerCase().contains(query) ||
          v.name.toLowerCase().contains(query) ||
          v.year.toLowerCase().contains(query) ||
          (v.vin?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  /// Sentinel لتمييز "لم يُمرَّر error" عن "تم تمرير null لمسح الخطأ"
  static const _keep = Object();

  VehicleState copyWith({
    List<Vehicle>? vehicles,
    Vehicle? selectedVehicle,
    String? searchQuery,
    bool? isLoading,
    Object? error = _keep, // يستخدم sentinel بدلاً من null
    bool? isInitialized,
    bool? isSuccess,
  }) {
    return VehicleState(
      vehicles: vehicles ?? this.vehicles,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      // إذا لم يُمرَّر error (sentinel)، احتفظ بالقيمة الحالية
      // إذا مُرِّر null صراحةً، امسح الخطأ
      // إذا مُرِّرت قيمة، استخدمها
      error: identical(error, _keep) ? this.error : error as String?,
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
    // منع تنفيذين متزامنين عند استدعاء forceRefresh مرتين متتاليتين
    if (state.isLoading) return;

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
        error: null, // مسح أي خطأ سابق عند النجاح
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

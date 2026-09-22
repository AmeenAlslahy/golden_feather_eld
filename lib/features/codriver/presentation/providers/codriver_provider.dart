import 'package:flutter_riverpod/flutter_riverpod.dart';

// ARCH-HIGH-01 fix: Import from composition root
import '../../../../app/providers/app_repository_providers.dart';
import '../../../../backend/contracts/contract_enums.dart';
import '../../../../backend/contracts/driver_session_backend.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/domain/shared/value_objects.dart';
import '../../domain/entities/codriver.dart';
import '../../domain/repositories/codriver_repository.dart';

// --- State and Notifier ---

/// حالة شاشة السائق المساعد
class CoDriverState {
  final List<CoDriver> availableDrivers;
  final CoDriver? selectedCoDriver;
  final bool isLoading;
  final bool isSwitching;
  final String? error;

  const CoDriverState({
    this.availableDrivers = const [],
    this.selectedCoDriver,
    this.isLoading = false,
    this.isSwitching = false,
    this.error,
  });

  CoDriverState copyWith({
    List<CoDriver>? availableDrivers,
    CoDriver? selectedCoDriver,
    bool? isLoading,
    bool? isSwitching,
    String? error,
  }) {
    return CoDriverState(
      availableDrivers: availableDrivers ?? this.availableDrivers,
      selectedCoDriver: selectedCoDriver ?? this.selectedCoDriver,
      isLoading: isLoading ?? this.isLoading,
      isSwitching: isSwitching ?? this.isSwitching,
      error: error,
    );
  }
}

/// مزود السائق المساعد
final codriverProvider =
    StateNotifierProvider<CoDriverNotifier, CoDriverState>((ref) {
  return CoDriverNotifier(
    repository: ref.watch(coDriverRepositoryProvider),
    driverSessionBackend: ref.watch(driverSessionBackendProvider),
  );
});

class CoDriverNotifier extends StateNotifier<CoDriverState> {
  final CoDriverRepository _repository;
  final DriverSessionBackend _driverSessionBackend;

  CoDriverNotifier(
      {required CoDriverRepository repository, required DriverSessionBackend driverSessionBackend})
      : _repository = repository,
        _driverSessionBackend = driverSessionBackend,
        super(const CoDriverState()) {
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.getAvailableDrivers();

    if (mounted) {
      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          error: failure.message,
        ),
        (drivers) => state = state.copyWith(
          isLoading: false,
          availableDrivers: drivers,
          error: null,
        ),
      );
    }
  }

  /// اختيار سائق مساعد
  void selectCoDriver(CoDriver driver) {
    state = state.copyWith(
      selectedCoDriver: driver.id == 'none' ? null : driver,
    );
  }

  /// تبديل الأدوار — مربوط بالـ API الحقيقي
  Future<bool> switchDrivers() async {
    final coDriver = state.selectedCoDriver;
    if (coDriver == null) {
      state = state.copyWith(error: 'No co-driver selected');
      return false;
    }
    state = state.copyWith(isSwitching: true, error: null);
    try {
      final driverId = int.tryParse(coDriver.id) ?? 0;
      final result = await _driverSessionBackend.switchPrimaryDriver(
        action: DutyStatusAction.switchPrimary,
        coDriverId: DriverId(driverId),
        reason: 'Driver requested switch',
      );
      return await result.fold(
        (error) {
          state = state.copyWith(isSwitching: false, error: error.code);
          return false;
        },
        (_) {
          state = state.copyWith(isSwitching: false, error: null);
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(isSwitching: false, error: e.toString());
      return false;
    }
  }
}

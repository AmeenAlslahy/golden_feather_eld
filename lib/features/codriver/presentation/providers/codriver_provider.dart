import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/codriver_repository_providers.dart';
import '../../domain/current_codriver.dart';
import '../../domain/entities/codriver.dart';
import '../../domain/repositories/codriver_repository.dart';

// --- State and Notifier ---

/// حالة شاشة السائق المساعد
class CoDriverState {
  final List<CoDriver> availableDrivers;
  final CoDriver? selectedCoDriver;
  final CurrentCoDriverRead? currentCoDriver;
  final String? currentError;
  final bool isLoading;
  final bool isSwitching;
  final String? error;

  const CoDriverState({
    this.availableDrivers = const [],
    this.selectedCoDriver,
    this.currentCoDriver,
    this.currentError,
    this.isLoading = false,
    this.isSwitching = false,
    this.error,
  });

  CoDriverState copyWith({
    List<CoDriver>? availableDrivers,
    CoDriver? selectedCoDriver,
    CurrentCoDriverRead? currentCoDriver,
    bool clearCurrent = false,
    String? currentError,
    bool clearCurrentError = false,
    bool? isLoading,
    bool? isSwitching,
    String? error,
  }) {
    return CoDriverState(
      availableDrivers: availableDrivers ?? this.availableDrivers,
      selectedCoDriver: selectedCoDriver ?? this.selectedCoDriver,
      currentCoDriver:
          clearCurrent ? currentCoDriver : (currentCoDriver ?? this.currentCoDriver),
      currentError:
          clearCurrentError ? currentError : (currentError ?? this.currentError),
      isLoading: isLoading ?? this.isLoading,
      isSwitching: isSwitching ?? this.isSwitching,
      error: error,
    );
  }
}

/// مزود السائق المساعد
final codriverProvider =
    StateNotifierProvider<CoDriverNotifier, CoDriverState>((ref) {
  return CoDriverNotifier(repository: ref.watch(coDriverRepositoryProvider));
});

class CoDriverNotifier extends StateNotifier<CoDriverState> {
  final CoDriverRepository _repository;

  CoDriverNotifier({required CoDriverRepository repository})
      : _repository = repository,
        super(const CoDriverState()) {
    _loadDrivers();
  }

  /// Pull-to-refresh / retry: re-reads the driver list and the current link.
  Future<void> reload() => _loadDrivers();

  Future<void> _loadDrivers() async {
    state = state.copyWith(isLoading: true, error: null);
    final driversResult = await _repository.getAvailableDrivers();
    final currentResult = await _repository.getCurrentCoDriver();
    if (!mounted) return;

    var next = state.copyWith(isLoading: false, error: null);
    driversResult.fold(
      (failure) => next = next.copyWith(error: failure.message),
      (drivers) => next = next.copyWith(availableDrivers: drivers, error: null),
    );
    currentResult.fold(
      (failure) => next = next.copyWith(
        error: next.error,
        currentError: failure.message,
        clearCurrent: true,
        clearCurrentError: true,
      ),
      (current) => next = next.copyWith(
        error: next.error,
        currentCoDriver: current,
        clearCurrentError: true,
      ),
    );
    state = next;
  }

  Future<void> _refreshCurrent() async {
    final currentResult = await _repository.getCurrentCoDriver();
    if (!mounted) return;
    currentResult.fold(
      (failure) => state = state.copyWith(
        error: state.error,
        currentError: failure.message,
        clearCurrent: true,
        clearCurrentError: true,
      ),
      (current) => state = state.copyWith(
        error: state.error,
        currentCoDriver: current,
        clearCurrentError: true,
      ),
    );
  }

  /// اختيار سائق مساعد
  void selectCoDriver(CoDriver driver) {
    state = state.copyWith(
      selectedCoDriver: driver.id == 'none' ? null : driver,
    );
  }

  /// Link or remove the session co-driver. Form co-driver is unchanged.
  Future<String?> applySessionCoDriver({
    required CoDriver driver,
    required String? uniqueId,
  }) async {
    final remove = driver.id == 'none' || driver.id.isEmpty;
    final coId = int.tryParse(driver.id);
    final result = await _repository.updateSessionCoDriver(
      remove: remove,
      coDriverId: remove ? null : coId,
      uniqueId: uniqueId,
    );
    if (!mounted) return 'Link was interrupted.';
    final message = result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return failure.message;
      },
      (_) {
        selectCoDriver(driver);
        state = state.copyWith(error: null);
        return null;
      },
    );
    if (message == null) await _refreshCurrent();
    return message;
  }

  /// تبديل الأدوار
  Future<String?> switchDrivers() async {
    final id = int.tryParse(state.selectedCoDriver?.id ?? '');
    if (id == null || id <= 0) {
      const message = 'Select a co-driver before switching.';
      state = state.copyWith(isSwitching: false, error: message);
      return message;
    }
    state = state.copyWith(isSwitching: true, error: null);
    final result = await _repository.switchPrimary(coDriverId: id);
    if (!mounted) return 'Switch was interrupted.';
    final message = result.fold(
      (failure) {
        state = state.copyWith(isSwitching: false, error: failure.message);
        return failure.message;
      },
      (_) {
        state = state.copyWith(isSwitching: false, error: null);
        return null;
      },
    );
    if (message == null) await _refreshCurrent();
    return message;
  }
}

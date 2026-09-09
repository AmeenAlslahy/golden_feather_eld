import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/core_providers.dart';
import '../../data/datasources/codriver_remote_data_source.dart';
import '../../data/repositories/codriver_repository_impl.dart';
import '../../domain/entities/codriver.dart';
import '../../domain/repositories/codriver_repository.dart';

// --- Dependency Injection Providers ---

final coDriverRemoteDataSourceProvider =
    Provider<CoDriverRemoteDataSource>((ref) {
  return CoDriverRemoteDataSourceImpl(
    apiClient: ref.watch(apiClientProvider),
    endpoints: ref.watch(endpointsProvider),
  );
});

final coDriverRepositoryProvider = Provider<CoDriverRepository>((ref) {
  return CoDriverRepositoryImpl(
    remoteDataSource: ref.watch(coDriverRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

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
  return CoDriverNotifier(repository: ref.watch(coDriverRepositoryProvider));
});

class CoDriverNotifier extends StateNotifier<CoDriverState> {
  final CoDriverRepository _repository;

  CoDriverNotifier({required CoDriverRepository repository})
      : _repository = repository,
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

  /// تبديل الأدوار
  Future<void> switchDrivers() async {
    state = state.copyWith(isSwitching: true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      state = state.copyWith(
        isSwitching: false,
        // بعد التبديل، السائق الحالي يصبح المساعد والعكس
      );
    }
  }
}

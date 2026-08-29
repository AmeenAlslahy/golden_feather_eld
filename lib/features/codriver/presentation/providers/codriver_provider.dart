import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/codriver_mock_data.dart';
import '../../domain/entities/codriver.dart';

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
final codriverProvider = StateNotifierProvider<CoDriverNotifier, CoDriverState>((ref) {
  return CoDriverNotifier();
});

class CoDriverNotifier extends StateNotifier<CoDriverState> {
  CoDriverNotifier() : super(const CoDriverState()) {
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final mockDrivers = CoDriverMockData.getCoDrivers();
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          availableDrivers: mockDrivers,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load co-drivers: ${e.toString()}',
        );
      }
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

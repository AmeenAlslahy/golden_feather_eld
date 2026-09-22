import 'package:flutter_riverpod/flutter_riverpod.dart';

// ARCH-HIGH-01 fix: Import from composition root
import '../../../../app/providers/app_repository_providers.dart';
import '../../../../core/services/tracking_config_storage_service.dart';
import '../../domain/entities/inspection_data.dart';
import '../../domain/repositories/inspection_repository.dart';

// --- State and Notifier ---

/// حالة التفتيش
class InspectionState {
  final bool isInspectionMode;
  final bool isPinLocked;
  final String? pinCode;
  final List<InspectionDayData> days;
  final bool isLoading;
  final String? error;

  const InspectionState({
    this.isInspectionMode = false,
    this.isPinLocked = false,
    this.pinCode,
    this.days = const [],
    this.isLoading = false,
    this.error,
  });

  InspectionState copyWith({
    bool? isInspectionMode,
    bool? isPinLocked,
    String? pinCode,
    List<InspectionDayData>? days,
    bool? isLoading,
    String? error,
  }) {
    return InspectionState(
      isInspectionMode: isInspectionMode ?? this.isInspectionMode,
      isPinLocked: isPinLocked ?? this.isPinLocked,
      pinCode: pinCode ?? this.pinCode,
      days: days ?? this.days,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// مزود التفتيش
final inspectionProvider =
    StateNotifierProvider<InspectionNotifier, InspectionState>((ref) {
  final repository = ref.watch(inspectionRepositoryProvider);
  final storageService = ref.watch(trackingConfigStorageProvider);
  return InspectionNotifier(
      repository: repository, storageService: storageService);
});

class InspectionNotifier extends StateNotifier<InspectionState> {
  final InspectionRepository _repository;
  final TrackingConfigStorageService _storageService;

  InspectionNotifier({
    required InspectionRepository repository,
    required TrackingConfigStorageService storageService,
  })  : _repository = repository,
        _storageService = storageService,
        super(const InspectionState());

  /// بدء وضع التفتيش
  Future<void> startInspection() async {
    state = state.copyWith(isLoading: true, error: null);

    // In a real scenario we'd need the logged in driver ID.
    // For now, assuming a default or extracting it from storage
    final driverId = int.tryParse(_storageService.deviceId) ?? 0;

    final result = await _repository.getInspectionReport(driverId);

    if (mounted) {
      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          error: failure.message,
        ),
        (days) => state = state.copyWith(
          isLoading: false,
          days: days,
          isInspectionMode: true,
          error: null,
        ),
      );
    }
  }

  /// تعيين رمز PIN
  void setPinCode(String pin) {
    state = state.copyWith(pinCode: pin);
  }

  /// فتح القفل
  bool unlock(String pin) {
    if (pin == state.pinCode) {
      state = state.copyWith(isPinLocked: false);
      return true;
    }
    return false;
  }

  /// قفل الشاشة
  void lock() {
    state = state.copyWith(isPinLocked: true);
  }

  /// إنهاء التفتيش
  void endInspection() {
    state = const InspectionState();
  }

  /// إرسال السجلات
  Future<bool> sendLogs(TransferMethod method,
      {String? email, bool isErods = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    final driverId = int.tryParse(_storageService.deviceId) ?? 0;
    final result = await _repository.exportInspectionData(
        driverId, method, email, isErods);

    if (mounted) {
      return result.fold(
        (failure) {
          state = state.copyWith(isLoading: false, error: failure.message);
          return false;
        },
        (_) {
          state = state.copyWith(isLoading: false, error: null);
          return true;
        },
      );
    }
    return false;
  }
}

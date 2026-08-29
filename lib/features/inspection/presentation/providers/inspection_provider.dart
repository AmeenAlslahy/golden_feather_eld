import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/inspection_mock_data.dart';
import '../../domain/entities/inspection_data.dart';

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
final inspectionProvider = StateNotifierProvider<InspectionNotifier, InspectionState>((ref) {
  return InspectionNotifier();
});

class InspectionNotifier extends StateNotifier<InspectionState> {
  InspectionNotifier() : super(const InspectionState());

  /// بدء وضع التفتيش
  Future<void> startInspection() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final mockDays = InspectionMockData.getLast8Days();
      state = state.copyWith(
        isLoading: false,
        days: mockDays,
        isInspectionMode: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start inspection: ${e.toString()}',
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
  Future<bool> sendLogs(TransferMethod method, {String? email, bool isErods = false}) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(isLoading: false);
    return true;
  }
}

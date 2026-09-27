import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../domain/repositories/log_repository.dart';
import '../../data/providers/log_repository_providers.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../backend/adapters/eld_engine/models/readiness_dto.dart';
import 'dart:typed_data';

class CertifyLogState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final ReadinessDto? readinessData;

  const CertifyLogState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.readinessData,
  });

  bool get isReady => readinessData?.readinessStatus == 'READY';
  List<String> get missingRequirements => readinessData?.missingRequirements ?? [];

  CertifyLogState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSuccess,
    ReadinessDto? readinessData,
  }) {
    return CertifyLogState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSuccess: isSuccess ?? this.isSuccess,
      readinessData: readinessData ?? this.readinessData,
    );
  }
}

final certifyLogProvider = StateNotifierProvider<CertifyLogNotifier, CertifyLogState>((ref) {
  final repository = ref.watch(logRepositoryProvider);
  return CertifyLogNotifier(
    repository,
    isArabic: ref.watch(localeProvider).languageCode == 'ar',
  );
});

class CertifyLogNotifier extends StateNotifier<CertifyLogState> {
  final LogRepository _repository;
  final bool _isArabic;

  /// Driver-facing text only — never the failure code or exception text.
  String _message(Failure failure) =>
      anyErrorUserMessage(failure, isArabic: _isArabic);

  CertifyLogNotifier(this._repository, {bool isArabic = false})
      : _isArabic = isArabic,
        super(const CertifyLogState());

  Future<String?> respondToCarrierEdit({
    required DailyLogId logId,
    required String editId,
    required String action,
    String? driverNotes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.respondToCarrierEdit(
      logId: logId,
      editId: editId,
      action: action,
      driverNotes: driverNotes,
    );
    if (!mounted) {
      return _isArabic ? 'انقطعت العملية. أعد المحاولة.' : 'Response was interrupted.';
    }
    final error = result.fold(_message, (_) => null);
    if (error != null) {
      state = state.copyWith(isLoading: false, error: error);
      return error;
    }
    await checkReadiness(logId);
    return null;
  }

  Future<void> checkReadiness(DailyLogId logId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getReadiness(logId);
    
    if (!mounted) return;
    
    result.match(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _message(failure),
        );
      },
      (data) {
        state = state.copyWith(
          isLoading: false,
          readinessData: data,
        );
      },
    );
  }

  Future<void> saveAndCertify({
    required DailyLogId logId,
    required DriverId driverId,
    required String logDate,
    required Uint8List signatureBytes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);
    
    // The live contract has no signature-upload path. The drawn signature
    // remains the driver's confirmation on this device; the legal record is
    // POST /eld/daily-logs/{id}/certify.
    if (signatureBytes.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: _isArabic ? 'ارسم التوقيع أولاً.' : 'Please draw a signature first.',
      );
      return;
    }

    final certifyResult = await _repository.certifyLog(
      logId: logId,
      driverId: driverId.value,
      logDate: logDate,
      signatureCertificateId: '',
      signatureConfirmation: true,
      certifiedTrue: true,
    );

    if (!mounted) return;

    certifyResult.match(
      (failure) {
        state = state.copyWith(isLoading: false, error: _message(failure));
      },
      (success) {
        state = state.copyWith(isLoading: false, isSuccess: true);
      },
    );
  }
}

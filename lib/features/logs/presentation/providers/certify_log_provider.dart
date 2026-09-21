import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/log_repository.dart';
import '../../data/repositories/log_repository_impl.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../backend/adapters/eld_engine/models/readiness_dto.dart';
import '../../../../backend/contracts/signature_backend.dart';
import '../../../../backend/providers/backend_providers.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../../../domain/signature/signature.dart';

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
  final signatureBackend = ref.watch(activeBackendProvider).signature;
  return CertifyLogNotifier(repository, signatureBackend);
});

class CertifyLogNotifier extends StateNotifier<CertifyLogState> {
  final LogRepository _repository;
  final SignatureBackend? _signatureBackend;

  CertifyLogNotifier(this._repository, this._signatureBackend) : super(const CertifyLogState());

  Future<void> checkReadiness(DailyLogId logId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getReadiness(logId);
    
    if (!mounted) return;
    
    result.match(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
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
    
    if (_signatureBackend == null) {
      state = state.copyWith(isLoading: false, error: 'Signature service unavailable.');
      return;
    }

    final signatureResult = await _signatureBackend.save(
      driverId: driverId,
      logDate: logDate,
      signatureDataBase64: base64Encode(signatureBytes),
      type: SignatureType.driverCertification,
    );

    await signatureResult.match(
      (error) async {
        state = state.copyWith(isLoading: false, error: 'Failed to save signature: ${error.l10nKey}');
      },
      (certificate) async {
        final certifyResult = await _repository.certifyLog(
          logId: logId,
          signatureCertificateId: certificate.signatureId,
          signatureConfirmation: true,
          certifiedTrue: true,
        );
        
        if (!mounted) return;

        certifyResult.match(
          (failure) {
            state = state.copyWith(isLoading: false, error: failure.message);
          },
          (success) {
            state = state.copyWith(isLoading: false, isSuccess: true);
          },
        );
      },
    );
  }
}

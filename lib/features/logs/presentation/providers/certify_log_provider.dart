import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/events/app_events.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../data/providers/log_repository_providers.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/entities/log_readiness.dart';
import '../../domain/repositories/log_repository.dart';

class CertifyLogState {
  final bool isLoading;
  final String? error;
  final LogReadiness? readinessData;

  static const String _statusReady = 'READY';

  const CertifyLogState({
    this.isLoading = false,
    this.error,
    this.readinessData,
  });

  bool get isReady => readinessData?.readinessStatus == _statusReady;
  List<String> get missingRequirements => readinessData?.missingRequirements ?? [];

  CertifyLogState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    LogReadiness? readinessData,
  }) {
    return CertifyLogState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      readinessData: readinessData ?? this.readinessData,
    );
  }
}

/// The driver's answer to a carrier-proposed edit (SRS 6).
enum CarrierEditResponse {
  accept('ACCEPT'),
  reject('REJECT');

  const CarrierEditResponse(this.apiValue);

  /// Wire value expected by POST /eld/daily-logs/{id}/carrier-edits/respond.
  final String apiValue;
}

/// Result of a driver action on the certify tab. The UI only renders
/// [message]; every decision has already been made by the notifier.
sealed class CertifyOutcome {
  const CertifyOutcome(this.message);
  final String message;
}

final class CertifySucceeded extends CertifyOutcome {
  const CertifySucceeded(super.message);
}

final class CertifyFailed extends CertifyOutcome {
  const CertifyFailed(super.message);
}

/// One notifier per log: readiness of log A can never leak into log B, and
/// the state is released as soon as the certify tab is closed.
final certifyLogProvider = StateNotifierProvider.autoDispose
    .family<CertifyLogNotifier, CertifyLogState, DailyLogId>((ref, logId) {
  final notifier = CertifyLogNotifier(
    ref,
    logId,
    ref.watch(logRepositoryProvider),
  );
  notifier._fetchReadiness();
  return notifier;
});

class CertifyLogNotifier extends StateNotifier<CertifyLogState> {
  final Ref _ref;
  final DailyLogId _logId;
  final LogRepository _repository;

  CertifyLogNotifier(this._ref, this._logId, this._repository)
      : super(const CertifyLogState(isLoading: true));

  /// Read lazily so a locale switch translates the next message without
  /// rebuilding the notifier (which would drop the loaded readiness).
  AppLocalizations get _loc => lookupAppLocalizations(_ref.read(localeProvider));

  /// Driver-facing text only — never the failure code or exception text.
  String _message(Failure failure) => anyErrorUserMessage(failure, loc: _loc);

  /// Re-fetch readiness (retry button, or after answering a carrier edit).
  Future<void> checkReadiness() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _fetchReadiness();
  }

  Future<void> _fetchReadiness() async {
    final result = await _repository.getReadiness(_logId);
    if (!mounted) return;
    state = result.match(
      (failure) => state.copyWith(isLoading: false, error: _message(failure)),
      (data) => state.copyWith(isLoading: false, readinessData: data),
    );
  }

  /// Accept / reject one carrier-proposed edit through the existing respond API.
  Future<CertifyOutcome> respondToCarrierEdit({
    required String editId,
    required CarrierEditResponse response,
    String? driverNotes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.respondToCarrierEdit(
      logId: _logId,
      editId: editId,
      action: response.apiValue,
      driverNotes: driverNotes,
    );
    if (!mounted) return CertifyFailed(_loc.responseInterrupted);

    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      state = state.copyWith(isLoading: false);
      return CertifyFailed(_message(failure));
    }

    await checkReadiness();
    if (state.error != null) {
      return CertifyFailed(state.error!);
    }

    return CertifySucceeded(
      response == CarrierEditResponse.accept
          ? _loc.carrierEditAcceptedReCertifyThe
          : _loc.carrierEditRejected,
    );
  }

  /// Certify [log] with the drawn signature. Returns `null` when a request is
  /// already in flight (double tap) so the UI shows nothing.
  Future<CertifyOutcome?> certify({
    required DailyLog log,
    required Uint8List? signatureBytes,
  }) async {
    if (state.isLoading) return null;

    if (!log.isFormComplete) return CertifyFailed(_loc.fillFormFirst);

    // The live contract has no signature-upload path. The drawn signature
    // remains the driver's confirmation on this device; the legal record is
    // POST /eld/daily-logs/{id}/certify.
    if (signatureBytes == null || signatureBytes.isEmpty) {
      return CertifyFailed(_loc.pleaseDrawASignatureFirst);
    }

    final driverId = _ref.read(currentDriverIdProvider);
    if (driverId == null) {
      return CertifyFailed(_loc.sessionMissingPleaseLogInAgain);
    }

    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.certifyLog(
      logId: _logId,
      driverId: driverId,
      // DateFormat is used for the API payload contract, not for UI display.
      logDate: DateFormat('yyyy-MM-dd').format(log.date),
      signatureCertificateId: 'local_drawn',
      signatureConfirmation: true,
      certifiedTrue: true,
    );
    if (!mounted) return null;
    state = state.copyWith(isLoading: false);

    return result.match(
      (failure) => CertifyFailed(_message(failure)),
      (_) {
        _ref.read(appEventBusProvider).fire(AppEvent.logDataChanged);
        return CertifySucceeded(_loc.logSuccessfullyCertified);
      },
    );
  }
}

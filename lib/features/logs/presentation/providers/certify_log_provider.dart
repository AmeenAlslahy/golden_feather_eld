import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/events/app_events.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../data/providers/log_repository_providers.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/entities/log_readiness.dart';
import '../../domain/entities/log_certify_state.dart';
import '../../domain/repositories/log_repository.dart';
import 'log_draft_signature_provider.dart';

class CertifyLogState {
  final bool isLoading;
  final String? error;
  final LogReadiness? readinessData;

  /// حالة شاشة الاعتماد من `GET /eld/daily-logs/{id}/certify` — المصدر
  /// الأول لقرار الجاهزية وموانع الاعتماد؛ null يعني غير متاحة
  /// (عقد أقدم/تعذر الجلب) فنعود للجاهزية وحدها.
  final LogCertifyState? certifyState;

  final CertifyOutcome? outcome;

  static const String _statusReady = 'READY';

  const CertifyLogState({
    this.isLoading = false,
    this.error,
    this.readinessData,
    this.certifyState,
    this.outcome,
  });

  bool get isReady {
    final cs = certifyState;
    if (cs != null) {
      if (cs.certified) return true;
      // SIGNATURE_REQUIRED لا يمنع الزر: التوقيع يُرسم ويُرسل مع نفس
      // طلب الاعتماد (الشاشة تتحقق من وجود التوقيع قبل الإرسال).
      final blocking = cs.validationCodes
          .where((code) => code.toUpperCase() != 'SIGNATURE_REQUIRED')
          .toList();
      if (blocking.isNotEmpty) return false;
      if (cs.canCertify) {
        return !(readinessData?.carrierProposedEditsPending ?? false);
      }
    }
    if (readinessData == null) return false;
    final status = readinessData!.readinessStatus.toUpperCase();
    if (status == _statusReady ||
        status == 'CERTIFIED' ||
        status == 'ALREADY_CERTIFIED') {
      return true;
    }
    return readinessData!.missingRequirements.isEmpty &&
        !readinessData!.carrierProposedEditsPending;
  }

  /// رموز الموانع كما وردت من الخادم (validationCodes أولاً، وإلا قائمة
  /// الجاهزية القديمة). ترجمة الرموز قرار العرض (loc) — لا نصوص
  /// إنجليزية مشفرة في الحالة (كانت خريطة كاملة هنا).
  List<String> get missingRequirements {
    final cs = certifyState;
    if (cs != null && cs.validationCodes.isNotEmpty) {
      return cs.validationCodes;
    }
    return readinessData?.missingRequirements ?? [];
  }

  CertifyLogState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    LogReadiness? readinessData,
    LogCertifyState? certifyState,
    CertifyOutcome? outcome,
    bool clearOutcome = false,
  }) {
    return CertifyLogState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      readinessData: readinessData ?? this.readinessData,
      certifyState: certifyState ?? this.certifyState,
      outcome: clearOutcome ? null : (outcome ?? this.outcome),
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
  const CertifySucceeded(super.message, {this.isLogCertified = false});
  final bool isLogCertified;
}

final class CertifyFailed extends CertifyOutcome {
  const CertifyFailed(super.message);
}

/// الطلب محفوظ في طابور المزامنة فقط؛ السجل ليس معتمدًا بعد.
/// الواجهة تعرضه تحذيرًا ولا تغلق الشاشة ولا تمسح التوقيع.
final class CertifyPending extends CertifyOutcome {
  const CertifyPending(super.message);
}

/// One notifier per log: readiness of log A can never leak into log B, and
/// the state is released as soon as the certify tab is closed.
final certifyLogProvider = StateNotifierProvider.autoDispose
    .family<CertifyLogNotifier, CertifyLogState, DailyLogId>((ref, logId) {
      return CertifyLogNotifier(ref, logId, ref.watch(logRepositoryProvider));
    });

class CertifyLogNotifier extends StateNotifier<CertifyLogState> {
  final Ref _ref;
  final DailyLogId _logId;
  final LogRepository _repository;

  CertifyLogNotifier(this._ref, this._logId, this._repository)
    : super(const CertifyLogState(isLoading: true));

  /// Read lazily so a locale switch translates the next message without
  /// rebuilding the notifier (which would drop the loaded readiness).
  AppLocalizations get _loc =>
      lookupAppLocalizations(_ref.read(localeProvider));

  /// Driver-facing text only — never the failure code or exception text.
  String _message(Failure failure) => anyErrorUserMessage(failure, loc: _loc);

  /// `200` باستجابة غير حاسمة ليس فشلاً تقنيًا: الخادم لم يؤكد الاعتماد.
  /// نعرض نصًا صريحًا بدل الرسالة العامة «تعذّر الطلب».
  String _certifyFailureMessage(Failure failure) {
    if (failure is ServerFailure &&
        failure.message == 'certificationNotConfirmed') {
      return _loc.certifyNotConfirmed;
    }
    return _message(failure);
  }

  /// Re-fetch readiness (retry button, or after answering a carrier edit).
  Future<void> checkReadiness() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearOutcome: true,
    );
    await _fetchReadiness();
  }

  Future<void> _fetchReadiness() async {
    final readinessResult = await _repository.getReadiness(_logId);

    // حالة شاشة الاعتماد (الوثيقة) — تُجلب إلى جانب الجاهزية؛ أي فشل
    // أو غياب (خادم بلا GET /certify) يبقى صامتاً ونتسامح معه.
    LogCertifyState? certifyState;
    try {
      final certifyResult = await _repository.getCertifyState(_logId);
      certifyState = certifyResult.fold((_) => null, (value) => value);
    } catch (error) {
      // حالة الاعتماد الجانبية اختيارية للعرض — فشلها يُسجَّل فقط.
      AppLogger.warning('Certify state fetch failed: $error');
      certifyState = null;
    }

    if (!mounted) return;
    state = readinessResult.match(
      (failure) {
        if (certifyState != null) {
          final fallbackReadiness = LogReadiness(
            dailyLogId: certifyState.dailyLogId != 0
                ? certifyState.dailyLogId
                : _logId.value,
            driverId: 0,
            driverName: '',
            logDate: certifyState.logDate,
            readinessStatus: certifyState.canCertify
                ? 'READY'
                : (certifyState.certified ? 'CERTIFIED' : 'NOT_READY'),
            missingRequirements: certifyState.validationCodes,
            legalStatement: certifyState.statementText,
            availableActions: certifyState.canCertify
                ? const ['CERTIFY']
                : const [],
            carrierProposedEditsPending: certifyState.validationCodes.contains(
              'UNCERTIFIED_EDITS_PENDING',
            ),
          );
          return state.copyWith(
            isLoading: false,
            readinessData: fallbackReadiness,
            certifyState: certifyState,
          );
        }
        return state.copyWith(
          isLoading: false,
          error: _message(failure),
          certifyState: certifyState,
        );
      },
      (data) => state.copyWith(
        isLoading: false,
        readinessData: data,
        certifyState: certifyState,
      ),
    );
  }

  /// Accept / reject one carrier-proposed edit through the existing respond API.
  Future<CertifyOutcome> respondToCarrierEdit({
    required String editId,
    required CarrierEditResponse response,
    String? driverNotes,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearOutcome: true,
    );
    final result = await _repository.respondToCarrierEdit(
      logId: _logId,
      editId: editId,
      action: response.apiValue,
      driverNotes: driverNotes,
    );
    if (!mounted) {
      return CertifyFailed(_loc.responseInterrupted);
    }

    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      final failOutcome = CertifyFailed(_message(failure));
      state = state.copyWith(isLoading: false, outcome: failOutcome);
      return failOutcome;
    }

    await checkReadiness();
    if (state.error != null) {
      final failOutcome = CertifyFailed(state.error!);
      state = state.copyWith(outcome: failOutcome);
      return failOutcome;
    }

    final successOutcome = CertifySucceeded(
      response == CarrierEditResponse.accept
          ? _loc.carrierEditAcceptedReCertifyThe
          : _loc.carrierEditRejected,
    );
    state = state.copyWith(outcome: successOutcome);
    return successOutcome;
  }

  /// Certify [log] with the drawn signature. Returns `null` when a request is
  /// already in flight (double tap) so the UI shows nothing.
  Future<CertifyOutcome?> certify({
    required DailyLog log,
    Uint8List? signatureBytes,
  }) async {
    if (state.isLoading) return null;

    if (log.isCertified) {
      final failOutcome = CertifyFailed(_loc.errBusinessRuleViolation);
      state = state.copyWith(outcome: failOutcome);
      return failOutcome;
    }

    if (!log.isFormComplete) {
      final failOutcome = CertifyFailed(_loc.fillFormFirst);
      state = state.copyWith(outcome: failOutcome);
      return failOutcome;
    }

    final bytes = signatureBytes;

    // الوثيقة تشترط وجود توقيع رقمي؛ التوقيع المرسوم يُرسل مع نفس طلب
    // الاعتماد في `signatureImage` (PNG base64).
    if (bytes == null || bytes.isEmpty) {
      final failOutcome = CertifyFailed(_loc.pleaseDrawASignatureFirst);
      state = state.copyWith(outcome: failOutcome);
      return failOutcome;
    }

    final driverId = _ref.read(currentDriverIdProvider);
    if (driverId == null) {
      final failOutcome = CertifyFailed(_loc.sessionMissingPleaseLogInAgain);
      state = state.copyWith(outcome: failOutcome);
      return failOutcome;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearOutcome: true,
    );
    // الوثيقة: جسم POST /certify = `{ certified: true, signatureImage }`
    // حيث signatureImage هي صورة التوقيع المرسوم (PNG base64).
    final result = await _repository.certifyLog(
      logId: _logId,
      driverId: driverId,
      certified: true,
      signatureImageBase64: base64Encode(bytes),
    );
    if (!mounted) return null;

    final outcome = result.match(
      (failure) => CertifyFailed(_certifyFailureMessage(failure)),
      (submission) {
        if (submission.isPendingSync) {
          // الأوفلاين: الطلب والتوقيع محفوظان في الطابور. لا نحذف المسودة
          // ولا نعلن الاعتماد؛ الشاشة تبقى مفتوحة لإعادة المحاولة. نطلق
          // تحديث القائمة كي يظهر السجل «بانتظار المزامنة» فوراً وبعد
          // إعادة فتح الشاشة (الحالة محفوظة في الكاش لا في الذاكرة).
          _ref.read(appEventBusProvider).fire(AppEvent.logDataChanged);
          return CertifyPending(_loc.certifyPendingSync);
        }
        _ref.read(logDraftSignatureProvider(_logId).notifier).clearDraft();
        _ref.read(appEventBusProvider).fire(AppEvent.logDataChanged);
        return CertifySucceeded(
          _loc.logSuccessfullyCertified,
          isLogCertified: true,
        );
      },
    );
    state = state.copyWith(isLoading: false, outcome: outcome);
    return outcome;
  }
}

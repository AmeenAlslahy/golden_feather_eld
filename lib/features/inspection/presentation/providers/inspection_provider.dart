import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/result/result.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../backend/contracts/inspection_backend.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../domain/inspection/dot_inspection.dart';
import '../../domain/entities/inspection_data.dart';
import '../../domain/inspection_transfer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/provider_cache.dart';

// --- Dependency Injection Providers ---

// --- State and Notifier ---

/// حالة التفتيش
class InspectionState {
  final bool isInspectionMode;
  final bool isPinLocked;
  final String? pinCode;
  final List<InspectionDayData> days;
  final List<DotInspectionCycleDay> cycle;
  final DotInspectionLog? log;
  final bool isLoading;
  final String? error;
  final String? transferMessage;

  const InspectionState({
    this.isInspectionMode = false,
    this.isPinLocked = false,
    this.pinCode,
    this.days = const [],
    this.cycle = const [],
    this.log,
    this.isLoading = false,
    this.error,
    this.transferMessage,
  });

  InspectionState copyWith({
    bool? isInspectionMode,
    bool? isPinLocked,
    String? pinCode,
    List<InspectionDayData>? days,
    List<DotInspectionCycleDay>? cycle,
    DotInspectionLog? log,
    bool clearLog = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? transferMessage,
    bool clearTransferMessage = false,
  }) {
    return InspectionState(
      isInspectionMode: isInspectionMode ?? this.isInspectionMode,
      isPinLocked: isPinLocked ?? this.isPinLocked,
      pinCode: pinCode ?? this.pinCode,
      days: days ?? this.days,
      cycle: cycle ?? this.cycle,
      log: clearLog ? log : (log ?? this.log),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      transferMessage:
          clearTransferMessage ? transferMessage : (transferMessage ?? this.transferMessage),
    );
  }
}

/// مزود التفتيش
final inspectionProvider =
    StateNotifierProvider<InspectionNotifier, InspectionState>((ref) {
  return InspectionNotifier(
    backend: ref.watch(inspectionBackendProvider),
    driverId: ref.watch(currentDriverIdProvider) ?? 0,
    loc: lookupAppLocalizations(ref.watch(localeProvider)),
  );
});

final informationPacketProvider =
    FutureProvider.autoDispose<InformationPacketView>((ref) async {
  cacheFor(ref, const Duration(minutes: 5));
  final driverId = ref.watch(currentDriverIdProvider);
  final result = await ref.watch(inspectionBackendProvider).getInformationPacket(
        driverId: driverId == null || driverId <= 0 ? null : DriverId(driverId),
      );
  return result.fold((error) => throw error, parseInformationPacket);
});

class InspectionNotifier extends StateNotifier<InspectionState> {
  final InspectionBackend _backend;
  final int _driverId;
  final AppLocalizations _loc;

  InspectionNotifier({
    required InspectionBackend backend,
    required int driverId,
    required AppLocalizations loc,
  })  : _backend = backend,
        _driverId = driverId,
        _loc = loc,
        super(const InspectionState());

  String _message(AppError error) {
    return appErrorUserMessage(error, loc: _loc);
  }

  /// بدء وضع التفتيش. الرمز يبقى في الذاكرة حتى يخرج السائق.
  Future<void> startInspection({required String pin}) async {
    state = state.copyWith(isLoading: true, clearError: true, clearLog: true);

    if (_driverId <= 0) {
      state = state.copyWith(
        isLoading: false,
        error: _loc.driverSessionMissingSignIn,
      );
      return;
    }

    final driver = DriverId(_driverId);
    final started = await _backend.startInspection(driverId: driver);
    if (!mounted) return;
    final startWarning = started.fold(_message, (_) => null);

    final cycleResult = await _backend.getCycle(driverId: driver, days: 8);
    if (!mounted) return;
    final cycle =
        cycleResult.fold((_) => const <DotInspectionCycleDay>[], (days) => days);
    final logResult = cycle.isEmpty
        ? await _backend.getLogs(driverId: driver)
        : await _backend.getLogs(driverId: driver, date: cycle.first.logDate);
    if (!mounted) return;

    final log = logResult.valueOrNull;
    final logError =
        logResult.errorOrNull == null ? null : _message(logResult.errorOrNull!);
    if (cycle.isEmpty && log == null) {
      state = state.copyWith(
        isLoading: false,
        isInspectionMode: false,
        error: startWarning ??
            logError ??
            cycleResult.fold(_message, (_) => null),
      );
      return;
    }

    state = state.copyWith(
      isLoading: false,
      isInspectionMode: true,
      isPinLocked: true,
      pinCode: pin,
      cycle: cycle,
      log: log,
      clearLog: log == null,
      error: startWarning,
    );
  }

  bool exitWithPin(String pin) {
    if (state.pinCode == null || pin != state.pinCode) return false;
    endInspection();
    return true;
  }

  Future<void> loadLog(DateTime date) async {
    if (_driverId <= 0) return;
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _backend.getLogs(
      driverId: DriverId(_driverId),
      date: date,
    );
    if (!mounted) return;
    result.fold(
      (error) => state = state.copyWith(
        isLoading: false,
        clearLog: true,
        error: _message(error),
      ),
      (log) => state = state.copyWith(isLoading: false, log: log, clearError: true),
    );
  }

  /// إنهاء التفتيش
  void endInspection() {
    state = const InspectionState();
  }

  /// إرسال السجلات
  Future<bool> sendLogs(
    TransferMethod method, {
    String? email,
    String? routingCode,
    required String comment,
  }) async {
    final commentError = inspectionCommentError(comment, loc: _loc);
    if (commentError != null) {
      state = state.copyWith(isLoading: false, error: commentError, clearTransferMessage: true);
      return false;
    }
    if (_driverId <= 0) {
      state = state.copyWith(
        isLoading: false,
        error: 'Driver session is missing. Sign in again before sending logs.',
        clearTransferMessage: true,
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearTransferMessage: true);
    final driver = DriverId(_driverId);
    final note = comment.trim();
    final route = routingCode?.trim();
    final recipient = email?.trim() ?? '';
    final result = method == TransferMethod.email && recipient.isNotEmpty
        ? await _backend.emailLogs(
            driverId: driver,
            recipientEmail: recipient,
            comment: note,
            routingCode: route == null || route.isEmpty ? null : route,
          )
        : await _backend.sendLogs(
            driverId: driver,
            transferType: transferTypeFor(method),
            outputFileComment: note,
            routingCode: route == null || route.isEmpty ? null : route,
            recipientEmail: (email == null || email.trim().isEmpty) ? null : email.trim(),
          );
    if (!mounted) return false;
    return result.fold(
      (error) {
        state = state.copyWith(isLoading: false, error: _message(error));
        return false;
      },
      (json) {
        final outcome = readTransferOutcome(json);
        state = state.copyWith(
          isLoading: false,
          clearError: outcome.accepted,
          error: outcome.accepted ? null : outcome.text,
          transferMessage: outcome.accepted ? outcome.text : null,
        );
        return outcome.accepted;
      },
    );
  }
}

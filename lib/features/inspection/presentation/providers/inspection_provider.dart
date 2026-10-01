import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/inspection_repository_providers.dart';
import '../../domain/repositories/inspection_repository.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../core/error/failure.dart';
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
    repository: ref.watch(inspectionRepositoryProvider),
    driverId: ref.watch(currentDriverIdProvider) ?? 0,
    loc: lookupAppLocalizations(ref.watch(localeProvider)),
  );
});

final informationPacketProvider =
    FutureProvider.autoDispose<InformationPacketView>((ref) async {
  cacheFor(ref, const Duration(minutes: 5));
  final driverId = ref.watch(currentDriverIdProvider);
  final result = await ref.watch(inspectionRepositoryProvider).getInformationPacket(
        driverId: driverId == null || driverId <= 0 ? null : DriverId(driverId),
      );
  return result.fold((error) => throw error, (packet) => packet);
});

class InspectionNotifier extends StateNotifier<InspectionState> {
  final InspectionRepository _repository;
  final int _driverId;
  final AppLocalizations _loc;

  InspectionNotifier({
    required InspectionRepository repository,
    required int driverId,
    required AppLocalizations loc,
  })  : _repository = repository,
        _driverId = driverId,
        _loc = loc,
        super(const InspectionState());

  String _message(Failure error) {
    return anyErrorUserMessage(error, loc: _loc);
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
    final started = await _repository.startInspection(driverId: driver);
    if (!mounted) return;
    final startWarning = started.fold(_message, (_) => null);

    final cycleResult = await _repository.getCycle(driverId: driver, days: 8);
    if (!mounted) return;
    final cycle =
        cycleResult.fold((_) => const <DotInspectionCycleDay>[], (days) => days);
    final logResult = cycle.isEmpty
        ? await _repository.getLogs(driverId: driver)
        : await _repository.getLogs(driverId: driver, date: cycle.first.logDate);
    if (!mounted) return;

    final log = logResult.fold((_) => null, (log) => log);
    final logError = logResult.fold(_message, (_) => null);
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
    final result = await _repository.getLogs(
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
    final result = await _repository.sendLogs(
        driverId: driver,
        method: method,
        email: recipient.isEmpty ? null : recipient,
        comment: note,
        routingCode: route,
    );

    if (!mounted) return false;
    return result.fold(
      (error) {
        state = state.copyWith(isLoading: false, error: _message(error));
        return false;
      },
      (outcome) {
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

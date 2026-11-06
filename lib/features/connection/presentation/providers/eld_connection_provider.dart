import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/session/session_epoch.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../tracking/data/providers/tracking_providers.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import '../../../vehicle/presentation/providers/vehicle_provider.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';

const Object _unsetConnectionField = Object();

class EldConnectionState {
  final bool isConnecting;
  final bool isContinuingDisconnected;
  final bool hasFailed;
  final bool wasCancelled;

  /// A connect/continue write has been dispatched and its server outcome is
  /// not known yet — either it is still in flight, or the user cancelled
  /// after dispatch. No second write may start while this is true.
  final bool serverRequestPending;

  /// The last terminal outcome did not prove the server session state.
  final bool sessionUnconfirmed;

  /// The last operation received a confirmed server success.
  final bool connectionConfirmed;

  /// Marker (`bluetooth_failed`, `connect_failed`, `disconnected_offline`,
  /// `disconnected_failed`, `disconnected_rejected`) — localized by the page.
  final String? errorMessage;

  /// Server-side failure, localized by the page in the *current* locale.
  final AppError? error;
  final String? infoMessage;

  EldConnectionState({
    this.isConnecting = false,
    this.isContinuingDisconnected = false,
    this.hasFailed = false,
    this.wasCancelled = false,
    this.serverRequestPending = false,
    this.sessionUnconfirmed = false,
    this.connectionConfirmed = false,
    this.errorMessage,
    this.error,
    this.infoMessage,
  });

  bool get isBusy => isConnecting || isContinuingDisconnected;

  EldConnectionState copyWith({
    bool? isConnecting,
    bool? isContinuingDisconnected,
    bool? hasFailed,
    bool? wasCancelled,
    bool? serverRequestPending,
    bool? sessionUnconfirmed,
    bool? connectionConfirmed,
    Object? errorMessage = _unsetConnectionField,
    Object? error = _unsetConnectionField,
    Object? infoMessage = _unsetConnectionField,
  }) {
    return EldConnectionState(
      isConnecting: isConnecting ?? this.isConnecting,
      isContinuingDisconnected:
          isContinuingDisconnected ?? this.isContinuingDisconnected,
      hasFailed: hasFailed ?? this.hasFailed,
      wasCancelled: wasCancelled ?? this.wasCancelled,
      serverRequestPending: serverRequestPending ?? this.serverRequestPending,
      sessionUnconfirmed: sessionUnconfirmed ?? this.sessionUnconfirmed,
      connectionConfirmed: connectionConfirmed ?? this.connectionConfirmed,
      errorMessage: identical(errorMessage, _unsetConnectionField)
          ? this.errorMessage
          : errorMessage as String?,
      error: identical(error, _unsetConnectionField)
          ? this.error
          : error as AppError?,
      infoMessage: identical(infoMessage, _unsetConnectionField)
          ? this.infoMessage
          : infoMessage as String?,
    );
  }
}

class EldConnectionNotifier extends StateNotifier<EldConnectionState> {
  static const String _connectRejectedCode = 'eld.session.connectRejected';
  static const String _connectUnconfirmedCode =
      'eld.session.connectUnconfirmed';

  final Ref _ref;

  /// Sequence covers both connect and continue-disconnected. A cancel or a
  /// switch from BLE connect to continue mode invalidates older callbacks.
  int _operationSeq = 0;

  /// Local single-flight latch. It prevents a second write while the first
  /// request is still awaiting a response. It is **not** server idempotency.
  bool _serverWriteInFlight = false;

  EldConnectionNotifier(this._ref) : super(EldConnectionState());

  bool get _serverWriteLocked =>
      _serverWriteInFlight || state.serverRequestPending;

  void _setServerPending(bool pending) {
    if (!mounted) return;
    state = state.copyWith(serverRequestPending: pending);
  }

  AppError _unconfirmedError() {
    return const ServerError(
      code: _connectUnconfirmedCode,
      l10nKey: 'sessionStatusUnconfirmed',
      context: {'reason': 'empty_success_payload'},
    );
  }

  /// Applies the locally selected vehicle identifier and starts phone
  /// tracking. This is called **only after** a confirmed server result.
  Future<void> _activateLocalSessionTracking() async {
    final selectedVehicle = _ref.read(vehicleProvider).selectedVehicle;
    final vUniqueId = selectedVehicle?.uniqueId;
    final targetDeviceId =
        selectedVehicle?.deviceId?.toString() ??
        ((vUniqueId != null && vUniqueId.isNotEmpty) ? vUniqueId : null);
    if (targetDeviceId != null) {
      try {
        await _ref.read(localStorageProvider).setDeviceId(targetDeviceId);
      } catch (_) {}
    }
    try {
      final config = await _ref
          .read(trackingRepositoryProvider)
          .getCurrentConfig();
      await _ref.read(trackingRepositoryProvider).updateConfig(config);
      await _ref.read(trackingStateProvider.notifier).startTracking();
    } catch (_) {}
  }

  Future<void> attemptConnection(String macAddress) async {
    // State-layer guard (not only a disabled button): no overlapping connect,
    // continue, or second server write while one is pending.
    if (state.isBusy || _serverWriteLocked) return;

    final seq = ++_operationSeq;
    state = state.copyWith(
      isConnecting: true,
      isContinuingDisconnected: false,
      hasFailed: false,
      wasCancelled: false,
      serverRequestPending: false,
      sessionUnconfirmed: false,
      connectionConfirmed: false,
      errorMessage: null,
      error: null,
      infoMessage: null,
    );

    try {
      final bluetoothService = _ref.read(bluetoothServiceProvider);

      // 1. الاتصال المحلي بالبلوتوث
      try {
        await bluetoothService.connect(macAddress);
      } catch (e) {
        if (!mounted || seq != _operationSeq) return;
        state = state.copyWith(
          isConnecting: false,
          hasFailed: true,
          wasCancelled: false,
          serverRequestPending: false,
          sessionUnconfirmed: false,
          connectionConfirmed: false,
          errorMessage: 'bluetooth_failed',
          error: null,
          infoMessage: null,
        );
        return;
      }

      if (!mounted || seq != _operationSeq) return;

      // 2. التحقق من السيرفر وبدء الجلسة
      final hardwareBackend = _ref.read(hardwareBackendProvider);

      final selectedUniqueId = _ref
          .read(vehicleProvider)
          .selectedVehicle
          ?.uniqueId;
      final result = await () async {
        _serverWriteInFlight = true;
        _setServerPending(true);
        try {
          return await hardwareBackend.connectSession(
            uniqueId: selectedUniqueId,
            driverId: _ref.read(currentDriverIdProvider) != null &&
                    _ref.read(currentDriverIdProvider)! > 0
                ? DriverId(_ref.read(currentDriverIdProvider)!)
                : null,
          );
        } finally {
          _serverWriteInFlight = false;
          _setServerPending(false);
        }
      }();

      if (!mounted || seq != _operationSeq) return;

      await result.fold<Future<void>>(
        (error) async {
          if (!mounted || seq != _operationSeq) return;

          final unconfirmed = error.code == _connectUnconfirmedCode;
          state = state.copyWith(
            isConnecting: false,
            hasFailed: !unconfirmed,
            wasCancelled: false,
            serverRequestPending: false,
            sessionUnconfirmed: unconfirmed,
            connectionConfirmed: false,
            errorMessage: null,
            error: error,
            infoMessage: null,
          );
        },
        (data) async {
          if (!mounted || seq != _operationSeq) return;

          if (data.isEmpty) {
            state = state.copyWith(
              isConnecting: false,
              hasFailed: false,
              wasCancelled: false,
              serverRequestPending: false,
              sessionUnconfirmed: true,
              connectionConfirmed: false,
              errorMessage: null,
              error: _unconfirmedError(),
              infoMessage: null,
            );
            return;
          }

          final driverObj = data['driver'];
          if (driverObj is Map) {
            final rawDriverId = driverObj['id'];
            final driverId = rawDriverId is int
                ? rawDriverId
                : (rawDriverId is num
                      ? rawDriverId.toInt()
                      : int.tryParse(rawDriverId?.toString() ?? ''));
            if (driverId != null && driverId > 0) {
              _ref.read(activeDriverIdProvider.notifier).state = (
                SessionEpoch.current,
                driverId,
              );
            }
          }

          await _activateLocalSessionTracking();

          if (!mounted || seq != _operationSeq) return;

          state = state.copyWith(
            isConnecting: false,
            hasFailed: false,
            wasCancelled: false,
            serverRequestPending: false,
            sessionUnconfirmed: false,
            connectionConfirmed: true,
            errorMessage: null,
            error: null,
            infoMessage: null,
          );
        },
      );
    } catch (e) {
      _serverWriteInFlight = false;
      if (mounted && seq == _operationSeq) {
        state = state.copyWith(
          isConnecting: false,
          hasFailed: true,
          wasCancelled: false,
          serverRequestPending: false,
          sessionUnconfirmed: false,
          connectionConfirmed: false,
          errorMessage: 'connect_failed',
          error: null,
          infoMessage: null,
        );
      }
    }
  }

  /// UX-001: إلغاء محاولة الاتصال الجارية وفك حجب الواجهة بأمان.
  ///
  /// Cancelling only cancels local waiters and the BLE link. Once HTTP has
  /// been dispatched, the server cannot be assumed to have cancelled its
  /// work; the state becomes explicitly unconfirmed instead.
  Future<void> cancelConnection() async {
    final wasDispatched = _serverWriteInFlight || state.serverRequestPending;
    _operationSeq++; // إبطال أي callbacks متأخرة للمحاولة السابقة
    try {
      final bluetoothService = _ref.read(bluetoothServiceProvider);
      await bluetoothService.disconnect();
    } catch (_) {}

    if (!mounted) return;

    state = state.copyWith(
      isConnecting: false,
      isContinuingDisconnected: false,
      hasFailed: false,
      wasCancelled: true,
      serverRequestPending: wasDispatched,
      sessionUnconfirmed: wasDispatched || state.sessionUnconfirmed,
      connectionConfirmed: false,
      errorMessage: null,
      error: null,
      infoMessage: null,
    );
  }

  /// `POST /eld/hardware/manual-mode` (§395.34 paper-log fallback).
  /// Returns null on success, otherwise a user-facing message. Never a raw dump.
  Future<String?> setManualMode({
    required bool enable,
    required String reason,
    required AppLocalizations loc,
  }) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      return loc.enterAReasonForManualRecording;
    }
    try {
      final result = await _ref
          .read(hardwareBackendProvider)
          .setManualMode(enable: enable, reason: trimmed);
      return await result.fold(
        (error) => anyErrorUserMessage(error, loc: loc),
        (_) => null,
      );
    } catch (_) {
      return loc.couldNotUpdateManualRecordingM;
    }
  }

  /// `POST /eld/sessions/connect` (manualMode = true). No reason form and no
  /// duty event. Local tracking is started only after a confirmed server
  /// result; offline, failure, and unconfirmed outcomes stay on this screen.
  Future<void> continueDisconnected() async {
    // A server write is already pending: never send a second one. If only the
    // BLE stage of a connect is running, switch modes and invalidate it before
    // any HTTP dispatch.
    if (state.serverRequestPending || state.isContinuingDisconnected) return;

    final seq = ++_operationSeq;
    state = state.copyWith(
      isConnecting: false,
      isContinuingDisconnected: true,
      hasFailed: false,
      wasCancelled: false,
      serverRequestPending: false,
      sessionUnconfirmed: false,
      connectionConfirmed: false,
      errorMessage: null,
      error: null,
      infoMessage: null,
    );

    try {
      try {
        final bluetoothService = _ref.read(bluetoothServiceProvider);
        await bluetoothService.disconnect();
      } catch (_) {}

      if (!mounted || seq != _operationSeq) return;

      final selectedVehicle = _ref.read(vehicleProvider).selectedVehicle;
      final vUniqueId = selectedVehicle?.uniqueId;

      // Only a confirmed offline state skips the request. Unknown connectivity
      // is not treated as proof of success or failure; the request result
      // remains the deciding evidence.
      if (_ref.read(isConnectedProvider).valueOrNull == false) {
        state = state.copyWith(
          isContinuingDisconnected: false,
          hasFailed: true,
          wasCancelled: false,
          serverRequestPending: false,
          sessionUnconfirmed: false,
          connectionConfirmed: false,
          errorMessage: 'disconnected_offline',
          error: null,
          infoMessage: null,
        );
        return;
      }

      final result = await () async {
        _serverWriteInFlight = true;
        _setServerPending(true);
        try {
          return await _ref
              .read(hardwareBackendProvider)
              .connectSession(
                uniqueId: vUniqueId,
                disconnected: true,
                driverId: _ref.read(currentDriverIdProvider) != null &&
                        _ref.read(currentDriverIdProvider)! > 0
                    ? DriverId(_ref.read(currentDriverIdProvider)!)
                    : null,
              );
        } finally {
          _serverWriteInFlight = false;
          _setServerPending(false);
        }
      }();

      if (!mounted || seq != _operationSeq) return;

      await result.fold<Future<void>>(
        (error) async {
          if (!mounted || seq != _operationSeq) return;

          final unconfirmed = error.code == _connectUnconfirmedCode;
          final rejected = error.code == _connectRejectedCode;
          state = state.copyWith(
            isContinuingDisconnected: false,
            hasFailed: !unconfirmed,
            wasCancelled: false,
            serverRequestPending: false,
            sessionUnconfirmed: unconfirmed,
            connectionConfirmed: false,
            errorMessage: unconfirmed
                ? null
                : (rejected ? 'disconnected_rejected' : 'disconnected_failed'),
            error: error,
            infoMessage: null,
          );
        },
        (data) async {
          if (!mounted || seq != _operationSeq) return;

          if (data.isEmpty) {
            state = state.copyWith(
              isContinuingDisconnected: false,
              hasFailed: false,
              wasCancelled: false,
              serverRequestPending: false,
              sessionUnconfirmed: true,
              connectionConfirmed: false,
              errorMessage: null,
              error: _unconfirmedError(),
              infoMessage: null,
            );
            return;
          }

          // Local activation happens only after the server result above was
          // strong enough to be confirmed.
          await _activateLocalSessionTracking();

          if (!mounted || seq != _operationSeq) return;

          state = state.copyWith(
            isContinuingDisconnected: false,
            hasFailed: false,
            wasCancelled: false,
            serverRequestPending: false,
            sessionUnconfirmed: false,
            connectionConfirmed: true,
            errorMessage: null,
            error: null,
            infoMessage: 'disconnected_accepted',
          );
        },
      );
    } catch (e) {
      _serverWriteInFlight = false;
      if (mounted && seq == _operationSeq) {
        state = state.copyWith(
          isContinuingDisconnected: false,
          hasFailed: true,
          wasCancelled: false,
          serverRequestPending: false,
          sessionUnconfirmed: false,
          connectionConfirmed: false,
          errorMessage: 'disconnected_failed',
          error: null,
          infoMessage: null,
        );
      }
    }
  }
}

final eldConnectionProvider =
    StateNotifierProvider.autoDispose<
      EldConnectionNotifier,
      EldConnectionState
    >((ref) {
      return EldConnectionNotifier(ref);
    });

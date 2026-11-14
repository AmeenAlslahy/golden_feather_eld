import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/bluetooth_service.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/session/session_epoch.dart';
import '../../../../core/utils/logger.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../tracking/data/providers/tracking_providers.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import '../../../tracking/presentation/providers/tracking_source_mode_provider.dart';
import '../../../vehicle/presentation/providers/vehicle_provider.dart';
import '../../../vehicle/domain/vehicle_selection.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../data/datasources/eld_session_snapshot_store.dart';
import '../../data/datasources/server_session_lookup.dart';
import '../../data/providers/eld_session_store_provider.dart';
import '../../domain/eld_session_snapshot.dart';

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
  ///
  /// **Servers only.** A session started while the server was unreachable does
  /// not set this flag; it sets [localSessionPendingSync] instead, and
  /// `EldSessionSyncService` confirms it later.
  final bool connectionConfirmed;

  /// A session was started locally while the server was unreachable.
  ///
  /// The driver may work and tracking runs, but nothing was written to the
  /// server yet. `EldSessionSyncService` replays it (GET-first) once
  /// connectivity returns. This is **not** an ambiguous dispatch
  /// ([sessionUnconfirmed]) and **not** a server confirmation.
  final bool localSessionPendingSync;

  /// Driver-facing success: either confirmed by the server or recorded
  /// locally with a pending sync.
  bool get sessionStarted => connectionConfirmed || localSessionPendingSync;

  /// Marker (`bluetooth_failed`, `connect_failed`, `vehicle_missing`,
  /// `session_conflict`, `disconnected_failed`, `disconnected_rejected`) —
  /// localized by the page.
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
    this.localSessionPendingSync = false,
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
    bool? localSessionPendingSync,
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
      localSessionPendingSync:
          localSessionPendingSync ?? this.localSessionPendingSync,
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
    // هوية قناة التتبع = uniqueId النصي فقط، وهي نفس الهوية المرسلة في
    // `POST /eld/sessions/connect`. المعرّف الرقمي `deviceId` يبقى لعقود
    // DVIR/الداشبورد ولا يصلح كـ `id` لبروتوكول OsmAnd.
    final targetDeviceId = resolveTrackingDeviceId(selectedVehicle);
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

  int? _currentDriverId() {
    final value = _ref.read(currentDriverIdProvider);
    return value != null && value > 0 ? value : null;
  }

  EldSessionSnapshotStore get _sessionStore =>
      _ref.read(eldSessionSnapshotStoreProvider);

  /// يحفظ لقطة "قيد الانتظار" **قبل** إرسال `POST /connect`.
  ///
  /// اللقطة هي أداة منع الازدواج: إن فُقد رد السيرفر (timeout) تبقى الجلسة
  /// معروفة محلياً، وعند إعادة المحاولة نقرأ `GET /sessions/{driverId}` أولاً
  /// بدل إنشاء جلسة ثانية.
  Future<void> _savePendingSnapshot({
    required int driverId,
    required String vehicleUniqueId,
    required String? vehicleName,
    required bool manualMode,
    String? bleMac,
  }) async {
    final existing = _sessionStore.load(driverId);
    if (existing != null &&
        existing.syncState == EldSessionSyncState.pending &&
        existing.vehicleUniqueId == vehicleUniqueId &&
        existing.manualMode == manualMode) {
      return; // حافظ على startedAt/localId الأصليين
    }
    await _sessionStore.save(
      EldSessionSnapshot(
        driverId: driverId,
        localId: const Uuid().v4(),
        vehicleUniqueId: vehicleUniqueId,
        vehicleName: vehicleName,
        manualMode: manualMode,
        startedAt: DateTime.now().toUtc(),
        origin: manualMode
            ? EldSessionOrigin.localManual
            : EldSessionOrigin.localPending,
        syncState: EldSessionSyncState.pending,
        bleMac: bleMac,
      ),
    );
  }

  /// يحفظ لقطة مؤكدة من رد `connect`.
  ///
  /// إن غاب `status`/`connectionStatus` (خادم أقدم) نعتبرها مؤكدة — لا
  /// نكسر السلوك الحالي. وإن وُجدا ورفضا الاتصال، تُحفظ اللقطة كـ pending
  /// ولا نعلن نجاحاً.
  Future<bool> _persistServerSnapshot({
    required Map<String, dynamic> data,
    required int driverId,
    required String vehicleUniqueId,
    required String? vehicleName,
    required bool manualMode,
    String? bleMac,
    String? serverMessage,
  }) async {
    final snapshot = EldSessionSnapshot.fromServerData(
      data,
      driverId: driverId,
      fallbackVehicleUniqueId: vehicleUniqueId,
      fallbackVehicleName: vehicleName,
      manualMode: manualMode,
      bleMac: bleMac,
      serverMessage: serverMessage,
    );
    // `connectionStatus` قد يغيب في خادم أقدم؛ الحكم حينها بـ `status`.
    final accepted = snapshot.confirmedByServer;
    await _sessionStore.save(
      accepted
          ? snapshot
          : snapshot.copyWith(
              syncState: EldSessionSyncState.pending,
              origin: manualMode
                  ? EldSessionOrigin.localManual
                  : EldSessionOrigin.localPending,
            ),
    );
    return accepted;
  }

  /// يحذف لقطة `pending` بعد رفض صريح من السيرفر (لا جلسة أُنشئت).
  ///
  /// بلا هذا الحذف كانت المزامنة تعيد إرسال طلب مرفوض عند كل عودة شبكة.
  Future<void> _clearRejectedSnapshot(
    int? driverId,
    String? vehicleUniqueId,
  ) async {
    if (driverId == null) return;
    final existing = _sessionStore.load(driverId);
    if (existing == null ||
        existing.syncState != EldSessionSyncState.pending) {
      return;
    }
    if (vehicleUniqueId != null &&
        existing.vehicleUniqueId != vehicleUniqueId) {
      return;
    }
    await _sessionStore.clear(driverId);
  }

  /// نتيجة محاولة تبنّي جلسة سيرفر موجودة قبل إرسال طلب جديد.
  ///
  /// **GET-first إلزامي:** لا يعتمد على وجود لقطة محلية، لأن أول تشغيل أو
  /// آخر جلسة `synced` لا يملكان لقطة `pending` — وكان ذلك يفوّت جلسة
  /// قائمة على السيرفر ويُنشئ ثانية.
  Future<_AdoptionOutcome> _adoptExistingSession({
    required int driverId,
    required String vehicleUniqueId,
    required bool manualMode,
    String? bleMac,
  }) async {
    final lookup = await lookupServerSession(
      backend: _ref.read(driverSessionBackendProvider),
      driverId: driverId,
    );
    if (lookup.state != ServerSessionState.active) {
      return const _AdoptionOutcome.none();
    }
    final server = lookup.snapshot!;
    if (server.vehicleUniqueId != null &&
        server.vehicleUniqueId != vehicleUniqueId) {
      return const _AdoptionOutcome.conflict();
    }
    final local = _sessionStore.load(driverId);
    final adopted = server.copyWith(
      localId: local?.localId,
      vehicleUniqueId: vehicleUniqueId,
      vehicleName: local?.vehicleName,
      manualMode: manualMode,
      bleMac: bleMac,
      syncState: EldSessionSyncState.synced,
      origin: EldSessionOrigin.server,
      lastSyncedAt: DateTime.now().toUtc(),
    );
    await _sessionStore.save(adopted);
    return _AdoptionOutcome.adopted(adopted);
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
      localSessionPendingSync: false,
      errorMessage: null,
      error: null,
      infoMessage: null,
    );

    try {
      final selectedVehicle = _ref.read(vehicleProvider).selectedVehicle;

      // 0. هوية المركبة إلزامية: `deviceId` في `POST /connect` هو
      // `vehicle.uniqueId` حصراً. السقوط إلى MAC كان يرسل معرّف البلوتوث
      // كمعرّف مركبة، أو يحذف `deviceId` نهائياً.
      final selectedUniqueId = readOperableUniqueId(selectedVehicle?.uniqueId);
      if (selectedUniqueId == null) {
        if (!mounted || seq != _operationSeq) return;
        state = state.copyWith(
          isConnecting: false,
          hasFailed: true,
          wasCancelled: false,
          serverRequestPending: false,
          sessionUnconfirmed: false,
          connectionConfirmed: false,
          localSessionPendingSync: false,
          errorMessage: 'vehicle_missing',
          error: null,
          infoMessage: null,
        );
        return;
      }

      // 1. الاتصال المحلي بالبلوتوث
      final bluetoothService = _ref.read(bluetoothServiceProvider);
      try {
        await bluetoothService.connect(macAddress);
        try {
          await _ref
              .read(trackingSourceModeProvider.notifier)
              .setBleDevice(macAddress: macAddress);
        } catch (_) {}
      } catch (e) {
        if (!mounted || seq != _operationSeq) return;
        final errorMsg = switch (e) {
          BluetoothException be when be.code == 'BT_DISABLED' =>
            'bluetooth_disabled',
          BluetoothException be when be.code == 'PERMISSION_DENIED' =>
            'bluetooth_permission_denied',
          BluetoothException be when be.code == 'INVALID_MAC' =>
            'bluetooth_invalid_mac',
          BluetoothException be when be.code == 'TIMEOUT' =>
            'bluetooth_timeout',
          _ => 'bluetooth_failed',
        };
        state = state.copyWith(
          isConnecting: false,
          hasFailed: true,
          wasCancelled: false,
          serverRequestPending: false,
          sessionUnconfirmed: false,
          connectionConfirmed: false,
          errorMessage: errorMsg,
          error: null,
          infoMessage: null,
        );
        return;
      }

      if (!mounted || seq != _operationSeq) return;

      // 2. التحقق من السيرفر وبدء الجلسة
      final hardwareBackend = _ref.read(hardwareBackendProvider);

      final driverId = _currentDriverId();
      final trimmedMac = macAddress.trim().isEmpty ? null : macAddress.trim();

      // 2أ. GET-first إلزامي: نتبنّى جلسة سيرفر نشطة قبل أي كتابة، حتى في
      // أول تشغيل أو بعد جلسة `synced` (لا نشترط لقطة `pending`).
      if (driverId != null) {
        final adoption = await _adoptExistingSession(
          driverId: driverId,
          vehicleUniqueId: selectedUniqueId,
          manualMode: false,
          bleMac: trimmedMac,
        );
        if (!mounted || seq != _operationSeq) return;
        if (adoption.conflict) {
          state = state.copyWith(
            isConnecting: false,
            hasFailed: true,
            errorMessage: 'session_conflict',
            error: null,
            infoMessage: null,
          );
          return;
        }
        final adopted = adoption.snapshot;
        if (adopted != null) {
          await _activateLocalSessionTracking();
          if (!mounted || seq != _operationSeq) return;
          state = state.copyWith(
            isConnecting: false,
            hasFailed: false,
            serverRequestPending: false,
            sessionUnconfirmed: false,
            connectionConfirmed: true,
            errorMessage: null,
            error: null,
            infoMessage: adopted.serverMessage ?? 'connected',
          );
          return;
        }

        // 2ب. لقطة "قيد الانتظار" قبل الكتابة — أداة منع الازدواج.
        await _savePendingSnapshot(
          driverId: driverId,
          vehicleUniqueId: selectedUniqueId,
          vehicleName: selectedVehicle?.name,
          manualMode: false,
          bleMac: trimmedMac,
        );
      }

      final result = await () async {
        _serverWriteInFlight = true;
        _setServerPending(true);
        try {
          return await hardwareBackend.connectSession(
            uniqueId: selectedUniqueId,
            disconnected: false,
            driverId:
                _ref.read(currentDriverIdProvider) != null &&
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

          // إذا نجح اتصال البلوتوث محلياً ولكن تعذر الوصول للسيرفر لعدم توفر إنترنت:
          // نسجل الجلسة محلياً ونبدأ التتبع. المزامنة الفعلية يقوم بها
          // `EldSessionSyncService` عند عودة الشبكة (GET-first ثم POST).
          if (error is NetworkError ||
              error.code.contains('network') ||
              error.code.contains('offline') ||
              error.code.contains('timeout')) {
            final effectiveDriverId = _currentDriverId() ?? driverId;
            if (effectiveDriverId != null) {
              await _savePendingSnapshot(
                driverId: effectiveDriverId,
                vehicleUniqueId: selectedUniqueId,
                vehicleName: selectedVehicle?.name,
                manualMode: false,
                bleMac: trimmedMac,
              );
            } else {
              AppLogger.warning(
                'Offline ELD session has no driver id — local only, no sync',
              );
            }
            await _activateLocalSessionTracking();
            if (!mounted || seq != _operationSeq) return;
            state = state.copyWith(
              isConnecting: false,
              hasFailed: false,
              wasCancelled: false,
              serverRequestPending: false,
              sessionUnconfirmed: false,
              connectionConfirmed: false,
              localSessionPendingSync: true,
              errorMessage: null,
              error: null,
              infoMessage: 'session_local_pending',
            );
            return;
          }

          final unconfirmed = error.code == _connectUnconfirmedCode;
          if (!unconfirmed) {
            // رفض صريح: لا جلسة على السيرفر، فلا معنى لإعادة المحاولة لاحقاً.
            await _clearRejectedSnapshot(driverId, selectedUniqueId);
          }
          state = state.copyWith(
            isConnecting: false,
            hasFailed: !unconfirmed,
            wasCancelled: false,
            serverRequestPending: false,
            sessionUnconfirmed: unconfirmed,
            connectionConfirmed: false,
            localSessionPendingSync: false,
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
              localSessionPendingSync: false,
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

          // لا نعلن النجاح قبل قراءة حكم السيرفر: قد يرد `success:true`
          // بجلسة غير نشطة أو غير متصلة. اللقطة هي المصدر المحلي بعد ذلك.
          final effectiveDriverId = _currentDriverId() ?? driverId;
          if (effectiveDriverId != null) {
            final rawMessage = data['serverMessage'] ?? data['message'];
            final accepted = await _persistServerSnapshot(
              data: data,
              driverId: effectiveDriverId,
              vehicleUniqueId: selectedUniqueId,
              vehicleName: selectedVehicle?.name,
              manualMode: false,
              bleMac: trimmedMac,
              serverMessage: rawMessage is String && rawMessage.trim().isNotEmpty
                  ? rawMessage.trim()
                  : null,
            );
            if (!mounted || seq != _operationSeq) return;
            if (!accepted) {
              state = state.copyWith(
                isConnecting: false,
                hasFailed: false,
                wasCancelled: false,
                serverRequestPending: false,
                sessionUnconfirmed: true,
                connectionConfirmed: false,
                localSessionPendingSync: false,
                errorMessage: null,
                error: _unconfirmedError(),
                infoMessage: null,
              );
              return;
            }
          }

          await _activateLocalSessionTracking();

          if (!mounted || seq != _operationSeq) return;

          final serverMessage =
              (data['serverMessage'] ?? data['message']) as String?;

          state = state.copyWith(
            isConnecting: false,
            hasFailed: false,
            wasCancelled: false,
            serverRequestPending: false,
            sessionUnconfirmed: false,
            connectionConfirmed: true,
            errorMessage: null,
            error: null,
            infoMessage:
                (serverMessage != null && serverMessage.trim().isNotEmpty)
                    ? serverMessage.trim()
                    : 'connected',
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
      localSessionPendingSync: false,
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
  /// duty event. Offline (or an unreachable server) records the session locally
  /// and starts tracking; [EldSessionSyncService] writes it later with a
  /// GET-first guard. Explicit rejections and unconfirmed dispatches stay on
  /// this screen without local activation.
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
      localSessionPendingSync: false,
      errorMessage: null,
      error: null,
      infoMessage: null,
    );

    try {
      final selectedVehicle = _ref.read(vehicleProvider).selectedVehicle;
      // هوية المركبة إلزامية: `deviceId` في `POST /connect` هو
      // `vehicle.uniqueId` حصراً — حتى في الوضع اليدوي.
      final vUniqueId = readOperableUniqueId(selectedVehicle?.uniqueId);
      if (vUniqueId == null) {
        if (!mounted || seq != _operationSeq) return;
        state = state.copyWith(
          isContinuingDisconnected: false,
          hasFailed: true,
          wasCancelled: false,
          serverRequestPending: false,
          sessionUnconfirmed: false,
          connectionConfirmed: false,
          localSessionPendingSync: false,
          errorMessage: 'vehicle_missing',
          error: null,
          infoMessage: null,
        );
        return;
      }

      try {
        final bluetoothService = _ref.read(bluetoothServiceProvider);
        await bluetoothService.disconnect();
      } catch (_) {}

      if (!mounted || seq != _operationSeq) return;

      final driverId = _currentDriverId();

      // التطبيق مصمم ليعمل أوفلاين وأونلاين:
      // عند عدم توفر الإنترنت، لا نحبس السائق في الشاشة بل نسجل الجلسة محلياً ونُفعّل التتبع
      if (_ref.read(isConnectedProvider).valueOrNull == false) {
        if (driverId != null) {
          await _savePendingSnapshot(
            driverId: driverId,
            vehicleUniqueId: vUniqueId,
            vehicleName: selectedVehicle?.name,
            manualMode: true,
          );
        } else {
          AppLogger.warning(
            'Offline ELD session has no driver id — local only, no sync',
          );
        }
        await _activateLocalSessionTracking();
        if (!mounted || seq != _operationSeq) return;
        state = state.copyWith(
          isContinuingDisconnected: false,
          hasFailed: false,
          wasCancelled: false,
          serverRequestPending: false,
          sessionUnconfirmed: false,
          connectionConfirmed: false,
          localSessionPendingSync: true,
          errorMessage: null,
          error: null,
          infoMessage: 'session_local_pending',
        );
        return;
      }

      // GET-first إلزامي: نتبنّى جلسة السيرفر النشطة قبل أي كتابة، بلا
      // اشتراط وجود لقطة `pending` (أول تشغيل / جلسة synced سابقة).
      if (driverId != null) {
        final adoption = await _adoptExistingSession(
          driverId: driverId,
          vehicleUniqueId: vUniqueId,
          manualMode: true,
        );
        if (!mounted || seq != _operationSeq) return;
        if (adoption.conflict) {
          state = state.copyWith(
            isContinuingDisconnected: false,
            hasFailed: true,
            errorMessage: 'session_conflict',
            error: null,
            infoMessage: null,
          );
          return;
        }
        final adopted = adoption.snapshot;
        if (adopted != null) {
          await _activateLocalSessionTracking();
          if (!mounted || seq != _operationSeq) return;
          state = state.copyWith(
            isContinuingDisconnected: false,
            hasFailed: false,
            serverRequestPending: false,
            sessionUnconfirmed: false,
            connectionConfirmed: true,
            localSessionPendingSync: false,
            errorMessage: null,
            error: null,
            infoMessage: 'disconnected_accepted',
          );
          return;
        }

        await _savePendingSnapshot(
          driverId: driverId,
          vehicleUniqueId: vUniqueId,
          vehicleName: selectedVehicle?.name,
          manualMode: true,
        );
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
                driverId:
                    _ref.read(currentDriverIdProvider) != null &&
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

          // عند حدوث خطأ في الشبكة (انقطاع أو مهلة)، نسجل الجلسة محلياً ونسمح للسائق بالمتابعة
          if (error is NetworkError ||
              error.code.contains('network') ||
              error.code.contains('offline') ||
              error.code.contains('timeout')) {
            if (!mounted || seq != _operationSeq) return;
            final effectiveDriverId = _currentDriverId() ?? driverId;
            if (effectiveDriverId != null) {
              await _savePendingSnapshot(
                driverId: effectiveDriverId,
                vehicleUniqueId: vUniqueId,
                vehicleName: selectedVehicle?.name,
                manualMode: true,
              );
            } else {
              AppLogger.warning(
                'Offline ELD session has no driver id — local only, no sync',
              );
            }
            await _activateLocalSessionTracking();
            if (!mounted || seq != _operationSeq) return;
            state = state.copyWith(
              isContinuingDisconnected: false,
              hasFailed: false,
              wasCancelled: false,
              serverRequestPending: false,
              sessionUnconfirmed: false,
              connectionConfirmed: false,
              localSessionPendingSync: true,
              errorMessage: null,
              error: null,
              infoMessage: 'session_local_pending',
            );
            return;
          }

          final unconfirmed = error.code == _connectUnconfirmedCode;
          final rejected = error.code == _connectRejectedCode;
          if (!unconfirmed) {
            await _clearRejectedSnapshot(driverId, vUniqueId);
          }
          state = state.copyWith(
            isContinuingDisconnected: false,
            hasFailed: !unconfirmed,
            wasCancelled: false,
            serverRequestPending: false,
            sessionUnconfirmed: unconfirmed,
            connectionConfirmed: false,
            localSessionPendingSync: false,
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
              localSessionPendingSync: false,
              errorMessage: null,
              error: _unconfirmedError(),
              infoMessage: null,
            );
            return;
          }

          // Local activation happens only after the server result above was
          // strong enough to be confirmed.
          final effectiveDriverId = _currentDriverId() ?? driverId;
          if (effectiveDriverId != null) {
            final accepted = await _persistServerSnapshot(
              data: data,
              driverId: effectiveDriverId,
              vehicleUniqueId: vUniqueId,
              vehicleName: selectedVehicle?.name,
              manualMode: true,
            );
            if (!mounted || seq != _operationSeq) return;
            if (!accepted) {
              state = state.copyWith(
                isContinuingDisconnected: false,
                hasFailed: false,
                wasCancelled: false,
                serverRequestPending: false,
                sessionUnconfirmed: true,
                connectionConfirmed: false,
                localSessionPendingSync: false,
                errorMessage: null,
                error: _unconfirmedError(),
                infoMessage: null,
              );
              return;
            }
          }

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

/// نتيجة محاولة تبنّي جلسة قائمة قبل إرسال طلب اتصال جديد.
class _AdoptionOutcome {
  /// الجلسة التي تبنّيناها (إن وجدت).
  final EldSessionSnapshot? snapshot;

  /// توجد جلسة نشطة على مركبة أخرى — لا يُسمح بتبنّيها ولا بإنشاء ثانية.
  final bool conflict;

  const _AdoptionOutcome._({this.snapshot, this.conflict = false});

  const _AdoptionOutcome.none() : this._();

  const _AdoptionOutcome.conflict() : this._(conflict: true);

  const _AdoptionOutcome.adopted(EldSessionSnapshot snapshot)
    : this._(snapshot: snapshot);
}

final eldConnectionProvider =
    StateNotifierProvider.autoDispose<
      EldConnectionNotifier,
      EldConnectionState
    >((ref) {
      return EldConnectionNotifier(ref);
    });

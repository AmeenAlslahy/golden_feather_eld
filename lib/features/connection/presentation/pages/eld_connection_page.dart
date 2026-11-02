import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/session/session_epoch.dart';
import '../../../../core/utils/startup_profiler.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../core/widgets/golden_app_bar.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../routes.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../../vehicle/domain/entities/vehicle.dart';
import '../../../vehicle/presentation/providers/vehicle_provider.dart';
import '../providers/hardware_status_provider.dart';
import '../mac_address_validation.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../tracking/data/providers/tracking_providers.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import '../../../../core/services/local_storage_service.dart';
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

  /// `POST /eld/hardware/connect?disconnected=true`. No reason form and no
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
              .connectSession(uniqueId: vUniqueId, disconnected: true);
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

class EldConnectionPage extends ConsumerStatefulWidget {
  const EldConnectionPage({super.key});

  @override
  ConsumerState<EldConnectionPage> createState() => _EldConnectionPageState();
}

class _EldConnectionPageState extends ConsumerState<EldConnectionPage> {
  final TextEditingController _macController = TextEditingController();

  /// آخر عربة طُبق معرفها على الحقل — اختيار عربة مختلفة لاحقاً
  /// (عودة من صفحة الاختيار) يملأ الحقل من جديد؛ أما الكتابة اليدوية
  /// بعد ذلك فتبقى للسائق ولا تُمس.
  String? _appliedVehicleKey;

  @override
  void initState() {
    super.initState();
    StartupProfiler.markOnce('first-interactive-page:connection');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Prefill only. An explicit user action is the only thing that may start
      // Bluetooth or a server write.
      _fillMacFromVehicle(
        ref.read(vehicleProvider).selectedVehicle,
        force: true,
      );
    });
  }

  /// يلصق ماك العربة في الحقل. [force] عند تغير الاختيار نفسه.
  void _fillMacFromVehicle(Vehicle? vehicle, {bool force = false}) {
    final uniqueId = vehicle?.uniqueId?.trim();
    if (uniqueId == null || uniqueId.isEmpty) return;
    final vehicleKey = vehicle?.id ?? uniqueId;
    final current = _macController.text.trim();
    if (force || current.isEmpty || current == _appliedVehicleKey) {
      _macController.text = uniqueId;
    }
    _appliedVehicleKey = vehicleKey;
  }

  @override
  void dispose() {
    _macController.dispose();
    super.dispose();
  }

  final _macFormKey = GlobalKey<FormState>();

  Future<void> _attemptConnection() async {
    // Required + MAC-shaped before any Bluetooth/server attempt.
    if (!(_macFormKey.currentState?.validate() ?? false)) return;
    final notifier = ref.read(eldConnectionProvider.notifier);
    await notifier.attemptConnection(_macController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardDataProvider);
    final connectionState = ref.watch(eldConnectionProvider);
    ref.listen(hardwareStatusProvider, (previous, next) {
      next.whenData((status) {
        final mac = status.macAddress;
        if (mac != null && _macController.text.trim().isEmpty) {
          _macController.text = mac;
        }
      });
    });
    // العودة من صفحة اختيار العربة باختيار جديد → لصق ماكها فوراً.
    ref.listen<Vehicle?>(vehicleProvider.select((s) => s.selectedVehicle), (
      previous,
      next,
    ) {
      if (next != null && next != previous) {
        _fillMacFromVehicle(next, force: true);
      }
    });

    // الانتقال للرئيسية فقط عند نتيجة خادم مؤكدة. أي فشل أو انقطاع أو نتيجة
    // غير مؤكدة يبقي المستخدم في هذه الشاشة.
    ref.listen<EldConnectionState>(eldConnectionProvider, (previous, current) {
      final confirmedNow =
          current.connectionConfirmed && previous?.connectionConfirmed != true;
      if (confirmedNow) {
        if (current.infoMessage == 'disconnected_accepted') {
          AppFeedback.info(context, context.loc.serverAcceptedDisconnected);
        }
        context.go(AppRoutes.home);
        return;
      }
      if (previous != null &&
          previous.isBusy &&
          !current.isBusy &&
          !current.connectionConfirmed &&
          !current.wasCancelled) {
        ref.invalidate(hardwareStatusProvider);
      }
    });

    final vehicleState = ref.watch(vehicleProvider);
    final selectedVehicle = vehicleState.selectedVehicle;

    String vehicleTitle;
    if (selectedVehicle != null && selectedVehicle.name.trim().isNotEmpty) {
      vehicleTitle = selectedVehicle.name.trim();
    } else if (selectedVehicle != null &&
        selectedVehicle.id.trim().isNotEmpty) {
      vehicleTitle = selectedVehicle.id.trim();
    } else if (dashboard.vehicleDisplayName.isNotEmpty &&
        dashboard.vehicleDisplayName != 'Select a vehicle' &&
        dashboard.vehicleDisplayName != 'No Vehicle') {
      vehicleTitle = dashboard.vehicleDisplayName;
    } else if (dashboard.vehicleId.isNotEmpty &&
        dashboard.vehicleId != 'No Vehicle' &&
        dashboard.vehicleId != 'Select a vehicle') {
      vehicleTitle = dashboard.vehicleId;
    } else {
      vehicleTitle = context.loc.selectVehicle;
    }

    return PopScope(
      canPop: !connectionState.isBusy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && connectionState.isBusy) {
          ref.read(eldConnectionProvider.notifier).cancelConnection();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: GoldenAppBar(
          variant: GoldenAppBarVariant.brand,
          titleText: vehicleTitle,
          leading: IconButton(
            tooltip: context.loc.selectVehicle,
            icon: Icon(
              Icons.compare_arrows,
              color: context.onGold,
              size: AppSpacing.iconSize,
            ),
            onPressed: () {
              context.push(AppRoutes.selectVehicle);
            },
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // نتيجة غير مؤكدة — ليست نجاحاً وليست فشلاً مؤكداً.
                  if (connectionState.sessionUnconfirmed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.warningContainer,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(
                            color: context.warning.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                          horizontal: AppSpacing.md,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: context.warning,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.loc.sessionStatusUnconfirmed,
                                    key: const Key(
                                      'session_unconfirmed_banner',
                                    ),
                                    style: context.styles.body.copyWith(
                                      color: context.warning,
                                      fontWeight: AppTypography.semiBold,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    context.loc.sessionStatusUnconfirmedHint,
                                    style: context.styles.body.copyWith(
                                      color: context.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // شريط التنبيه عند فشل الاتصال
                  if (connectionState.hasFailed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.colors.errorContainer,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(
                            color: context.colors.error.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                          horizontal: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: context.colors.error,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _connectionErrorMessage(
                                  context,
                                  connectionState,
                                ),
                                style: context.styles.body.copyWith(
                                  color: context.colors.onErrorContainer,
                                  fontWeight: AppTypography.semiBold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ─── 1. Checklist Card ───
                  EldCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: context.gold.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.checklist_rtl_rounded,
                                color: context.gold,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                context.loc.verifyFollowingItems,
                                key: const Key('connection_checklist_title'),
                                style: context.styles.cardTitle.copyWith(
                                  fontWeight: AppTypography.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.compact),
                        _buildChecklistItem(context.loc.macEnteredCorrectly),
                        _buildChecklistItem(
                          context.loc.hardwareProperlyInstalled,
                        ),
                        _buildChecklistItem(context.loc.vehiclePowerOn),
                        _buildChecklistItem(context.loc.bluetoothEnabled),
                        _buildChecklistItem(context.loc.gpsEnabled),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ─── 2. MAC Address Input & Connect Actions Card ───
                  EldCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: context.gold.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.bluetooth_searching_rounded,
                                color: context.gold,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                context.loc.enterMacAddress,
                                style: context.styles.cardTitle.copyWith(
                                  fontWeight: AppTypography.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        Form(
                          key: _macFormKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: AppTextField(
                              controller: _macController,
                              hint: 'AA:BB:CC:DD:EE:FF',
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.done,
                              maxLength: 17,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9a-zA-Z:-]'),
                                ),
                              ],
                              onSubmitted: (_) => _attemptConnection(),
                              validator: (v) =>
                                  macAddressError(v, loc: context.loc),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // ✅ زر اتصال بلون الهوية الذهبي الأساسي
                        AppButton(
                          label: context.loc.connect,
                          type: EldButtonType.primary,
                          isLoading: connectionState.isConnecting,
                          onPressed:
                              connectionState.isBusy ||
                                  connectionState.serverRequestPending
                              ? null
                              : _attemptConnection,
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // ✅ زر متابعة بدون اتصال بالدور الثانوي.
                        // يُقبل أثناء مرحلة BLE فقط، لا أثناء طلب خادم معلّق.
                        AppButton(
                          label: context.loc.continueDisconnected,
                          type: EldButtonType.secondary,
                          isLoading: connectionState.isContinuingDisconnected,
                          onPressed:
                              connectionState.isContinuingDisconnected ||
                                  connectionState.serverRequestPending
                              ? null
                              : () => ref
                                    .read(eldConnectionProvider.notifier)
                                    .continueDisconnected(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (connectionState.isBusy)
              Container(
                color: context.colors.scrim.withValues(alpha: 0.38),
                alignment: Alignment.center,
                // استثناء موثق: بطاقة عائمة فوق scrim أثناء التوصيل —
                // تحتاج ظل حوار (8) لا ظل بطاقة النظام؛ ليست بطاقة محتوى.
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(width: AppSpacing.md),
                            Flexible(
                              child: Text(
                                connectionState.isContinuingDisconnected
                                    ? context.loc.continueDisconnectedInProgress
                                    : context.loc.connecting,
                                style: context.styles.bodyBold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            TextButton(
                              key: const Key('cancel_connection_button'),
                              onPressed: () => ref
                                  .read(eldConnectionProvider.notifier)
                                  .cancelConnection(),
                              child: Text(context.loc.cancelButton),
                            ),
                            if (connectionState.isConnecting)
                              TextButton(
                                key: const Key(
                                  'continue_disconnected_overlay_button',
                                ),
                                // لا كتابة خادم ثانية أثناء طلب معلّق.
                                onPressed: connectionState.serverRequestPending
                                    ? null
                                    : () => ref
                                          .read(eldConnectionProvider.notifier)
                                          .continueDisconnected(),
                                child: Text(context.loc.continueDisconnected),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ), // PopScope child Scaffold
    );
  }

  String _connectionErrorMessage(
    BuildContext context,
    EldConnectionState state,
  ) {
    final loc = AppLocalizations.of(context)!;
    switch (state.errorMessage) {
      case 'disconnected_offline':
        return loc.continueDisconnectedOffline;
      case 'disconnected_rejected':
        return loc.continueDisconnectedRejected;
      case 'disconnected_failed':
        final detail = state.error == null
            ? null
            : anyErrorUserMessage(state.error!, loc: loc);
        return detail == null || detail.isEmpty
            ? loc.continueDisconnectedFailed
            : '${loc.continueDisconnectedFailed} $detail';
    }
    return _friendlyConnectionError(
      context,
      state.errorMessage,
      state.error,
      _macController.text,
    );
  }

  /// SRS 9.3 #9: the failure names the ELD the driver targeted
  /// («Unable to connect to ELD with MAC 44A4»), never a raw exception.
  String _friendlyConnectionError(
    BuildContext context,
    String? raw,
    AppError? error,
    String mac,
  ) {
    final loc = AppLocalizations.of(context)!;
    final target = mac.trim();
    final head = target.isEmpty
        ? loc.unableToConnectToEld
        : '${context.loc.unableToConnect} $target.';
    if (error != null) {
      if (error.code == 'eld.session.connectRejected') {
        return '$head ${loc.sessionConnectRejected}';
      }
      if (error.code == 'eld.session.connectUnconfirmed') {
        return loc.sessionStatusUnconfirmed;
      }
      return '$head ${anyErrorUserMessage(error, loc: loc)}';
    }
    if (raw == 'bluetooth_failed') {
      return '$head ${loc.checkBluetoothAndRetry}';
    }
    return '$head ${loc.checkNetworkAndRetry}';
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.compact),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsetsDirectional.only(
              top: 7,
              end: AppSpacing.sm + 2,
            ),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: context.gold,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(child: Text(text, style: context.styles.body)),
        ],
      ),
    );
  }
}

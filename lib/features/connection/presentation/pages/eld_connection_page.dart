import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
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

class EldConnectionState {
  final bool isConnecting;
  final bool hasFailed;

  /// Marker (`bluetooth_failed`, `connect_failed`) — localized by the page.
  final String? errorMessage;

  /// Server-side failure, localized by the page in the *current* locale.
  final AppError? error;
  final String? infoMessage;

  EldConnectionState({
    this.isConnecting = false,
    this.hasFailed = false,
    this.errorMessage,
    this.error,
    this.infoMessage,
  });

  EldConnectionState copyWith({
    bool? isConnecting,
    bool? hasFailed,
    String? errorMessage,
    AppError? error,
    String? infoMessage,
  }) {
    return EldConnectionState(
      isConnecting: isConnecting ?? this.isConnecting,
      hasFailed: hasFailed ?? this.hasFailed,
      errorMessage: errorMessage,
      error: error,
      infoMessage: infoMessage,
    );
  }
}

class EldConnectionNotifier extends StateNotifier<EldConnectionState> {
  final Ref _ref;

  EldConnectionNotifier(this._ref) : super(EldConnectionState());

  Future<void> attemptConnection(String macAddress) async {
    state = state.copyWith(
      isConnecting: true,
      hasFailed: false,
      errorMessage: null,
    );

    try {
      final bluetoothService = _ref.read(bluetoothServiceProvider);

      // 1. الاتصال المحلي بالبلوتوث
      try {
        await bluetoothService.connect(macAddress);
      } catch (e) {
        if (mounted) {
          state = state.copyWith(
            isConnecting: false,
            hasFailed: true,
            errorMessage: 'bluetooth_failed',
          );
        }
        return;
      }

      // 2. التحقق من السيرفر وبدء الجلسة
      final hardwareBackend = _ref.read(hardwareBackendProvider);

      final selectedUniqueId = _ref
          .read(vehicleProvider)
          .selectedVehicle
          ?.uniqueId;
      final result = await hardwareBackend.connectSession(
        uniqueId: selectedUniqueId,
      );

      if (mounted) {
        result.fold(
          (error) {
            state = state.copyWith(
              isConnecting: false,
              hasFailed: true,
              error: error,
            );
          },
          (data) async {
            // تفعيل خدمة تتبع Traccar Client بالهاتف متزامنة مع المركبة
            final selectedVehicle = _ref.read(vehicleProvider).selectedVehicle;
            final vUniqueId = selectedVehicle?.uniqueId;
            final targetDeviceId =
                selectedVehicle?.deviceId?.toString() ??
                ((vUniqueId != null && vUniqueId.isNotEmpty)
                    ? vUniqueId
                    : null);
            if (targetDeviceId != null) {
              await _ref.read(localStorageProvider).setDeviceId(targetDeviceId);
            }
            try {
              final config = await _ref
                  .read(trackingRepositoryProvider)
                  .getCurrentConfig();
              await _ref.read(trackingRepositoryProvider).updateConfig(config);
              await _ref.read(trackingStateProvider.notifier).startTracking();
            } catch (_) {}

            state = state.copyWith(isConnecting: false, hasFailed: false);
          },
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isConnecting: false,
          hasFailed: true,
          errorMessage: 'connect_failed',
        );
      }
    }
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

  /// `POST /eld/hardware/connect?disconnected=true`. No reason form and no duty event.
  Future<void> continueDisconnected() async {
    final selectedVehicle = _ref.read(vehicleProvider).selectedVehicle;
    final vUniqueId = selectedVehicle?.uniqueId;
    final targetDeviceId =
        selectedVehicle?.deviceId?.toString() ??
        ((vUniqueId != null && vUniqueId.isNotEmpty) ? vUniqueId : null);
    if (targetDeviceId != null) {
      await _ref.read(localStorageProvider).setDeviceId(targetDeviceId);
    }
    try {
      final config = await _ref
          .read(trackingRepositoryProvider)
          .getCurrentConfig();
      await _ref.read(trackingRepositoryProvider).updateConfig(config);
      await _ref.read(trackingStateProvider.notifier).startTracking();
    } catch (_) {}

    final online = _ref.read(isConnectedProvider).value ?? true;
    if (online) {
      try {
        await _ref
            .read(hardwareBackendProvider)
            .connectSession(uniqueId: vUniqueId, disconnected: true);
      } catch (_) {}
    }

    if (mounted) {
      state = state.copyWith(
        isConnecting: false,
        hasFailed: false,
        errorMessage: null,
        infoMessage: 'disconnected_accepted',
      );
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fillMacFromVehicle(
        ref.read(vehicleProvider).selectedVehicle,
        force: true,
      );
      if (_macController.text.trim().isNotEmpty) {
        _attemptConnection();
      }
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

    // الانتقال للرئيسية عند النجاح
    ref.listen<EldConnectionState>(eldConnectionProvider, (previous, current) {
      if (current.infoMessage == 'disconnected_accepted' &&
          previous?.infoMessage != 'disconnected_accepted') {
        AppFeedback.info(context, context.loc.serverAcceptedDisconnected);
        context.go(AppRoutes.home);
        return;
      }
      if (previous != null &&
          previous.isConnecting &&
          !current.isConnecting &&
          !current.hasFailed) {
        context.go(AppRoutes.home);
      } else if (previous != null &&
          previous.isConnecting &&
          !current.isConnecting) {
        ref.invalidate(hardwareStatusProvider);
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        // أيقونة الإجراء تفتح دائماً صفحة اختيار العربة (مع الحفاظ على
        // الرجوع) — لا تخرج لصفحة أخرى أبداً.
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
        title: Text(
          dashboard.vehicleDisplayName.isNotEmpty &&
                  dashboard.vehicleDisplayName != 'No Vehicle'
              ? dashboard.vehicleDisplayName
              : dashboard.vehicleId,
          style: context.styles.appBarTitle,
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // شريط التنبيه الأحمر
                if (connectionState.hasFailed)
                  Container(
                    color: context.colors.error,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      _friendlyConnectionError(
                        context,
                        connectionState.errorMessage,
                        connectionState.error,
                        _macController.text,
                      ),
                      style: context.styles.button,
                      textAlign: TextAlign.center,
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SRS 9.3 step 5: the five-item checklist is part of the
                      // connection screen itself, not only of the failure state.
                      Text(
                        context.loc.verifyFollowingItems,
                        key: const Key('connection_checklist_title'),
                        style: context.styles.body,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildChecklistItem(context.loc.macEnteredCorrectly),
                      _buildChecklistItem(
                        context.loc.hardwareProperlyInstalled,
                      ),
                      _buildChecklistItem(context.loc.vehiclePowerOn),
                      _buildChecklistItem(context.loc.bluetoothEnabled),
                      _buildChecklistItem(context.loc.gpsEnabled),
                      const SizedBox(height: AppSpacing.lg),
                      Divider(color: Theme.of(context).dividerColor, height: 1),
                      const SizedBox(height: AppSpacing.lg),

                      // عنوان حقل MAC
                      Text(
                        context.loc.enterMacAddress,
                        style: context.styles.body,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // ✅ حقل إدخال موحد
                      Form(
                        key: _macFormKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
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

                      const SizedBox(height: AppSpacing.xl),

                      // ✅ زر اتصال
                      AppButton(
                        label: context.loc.connect,
                        type: EldButtonType.connect,
                        isLoading: connectionState.isConnecting,
                        onPressed: connectionState.isConnecting
                            ? null
                            : _attemptConnection,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // ✅ زر متابعة بدون اتصال
                      AppButton(
                        label: context.loc.continueDisconnected,
                        type: EldButtonType.continueDisconnected,
                        onPressed: connectionState.isConnecting
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
          if (connectionState.isConnecting)
            Container(
              color: context.colors.scrim.withValues(alpha: 0.38),
              alignment: Alignment.center,
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        context.loc.connecting,
                        style: context.styles.bodyBold,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
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
      return '$head ${anyErrorUserMessage(error, loc: loc)}';
    }
    if (raw == 'bluetooth_failed') {
      return '$head ${loc.checkBluetoothAndRetry}';
    }
    return '$head ${loc.checkNetworkAndRetry}';
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        bottom: AppSpacing.sm,
        start: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ نقطة بسيطة بدلاً من CircleAvatar
          const Padding(
            padding: EdgeInsetsDirectional.only(
              top: AppSpacing.sm,
              end: AppSpacing.sm,
            ),
            child: Icon(Icons.circle, size: AppSpacing.iconBullet),
          ),
          Expanded(child: Text(text, style: context.styles.subtitle)),
        ],
      ),
    );
  }
}

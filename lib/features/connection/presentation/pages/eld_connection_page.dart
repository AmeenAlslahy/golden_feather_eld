import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_feather_eld/routes/app_routes.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/startup_profiler.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../core/widgets/golden_app_bar.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../../vehicle/domain/entities/vehicle.dart';
import '../../../vehicle/presentation/providers/vehicle_provider.dart';
import '../providers/hardware_status_provider.dart';
import '../providers/eld_connection_provider.dart';
import '../mac_address_validation.dart';
import '../widgets/connection_checklist_card.dart';
import '../widgets/connecting_overlay.dart';
import '../widgets/connection_status_banner.dart';

// Re-export provider and state for existing tests and consumers
export '../providers/eld_connection_provider.dart';

class EldConnectionPage extends ConsumerStatefulWidget {
  const EldConnectionPage({super.key});

  @override
  ConsumerState<EldConnectionPage> createState() => _EldConnectionPageState();
}

class _EldConnectionPageState extends ConsumerState<EldConnectionPage> {
  final TextEditingController _macController = TextEditingController();
  final _macFormKey = GlobalKey<FormState>();

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

  Future<void> _attemptConnection() async {
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

    ref.listen<Vehicle?>(vehicleProvider.select((s) => s.selectedVehicle), (
      previous,
      next,
    ) {
      if (next != null && next != previous) {
        _fillMacFromVehicle(next, force: true);
      }
    });

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

    // العنوان: رقم المركبة فقط — لا اسم ولا موديل ولا سنة.
    String vehicleTitle;
    if (selectedVehicle != null && selectedVehicle.id.trim().isNotEmpty) {
      vehicleTitle = selectedVehicle.id.trim();
    } else if (dashboard.vehicleId.isNotEmpty &&
        dashboard.vehicleId != 'No Vehicle' &&
        dashboard.vehicleId != 'Select a vehicle') {
      vehicleTitle = dashboard.vehicleId;
    } else if (selectedVehicle != null &&
        selectedVehicle.name.trim().isNotEmpty) {
      // احتياطي فقط عند غياب الرقم نهائياً.
      vehicleTitle = selectedVehicle.name.trim();
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
                  if (connectionState.sessionUnconfirmed)
                    const SessionUnconfirmedBanner(),

                  if (connectionState.hasFailed)
                    ConnectionFailureBanner(
                      message: _connectionErrorMessage(
                        context,
                        connectionState,
                      ),
                    ),

                  // ─── 1. Checklist Card ───
                  const ConnectionChecklistCard(),

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

                        // لا مؤشر تحميل داخل الزر: النافذة العائمة أعلاه
                        // تعرض التقدّم، فتكرار المؤشر خلفها يوحي بعمليتين.
                        AppButton(
                          label: context.loc.connect,
                          type: EldButtonType.primary,
                          onPressed:
                              connectionState.isBusy ||
                                  connectionState.serverRequestPending
                              ? null
                              : _attemptConnection,
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        AppButton(
                          label: context.loc.continueDisconnected,
                          type: EldButtonType.secondary,
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
              ConnectingOverlay(
                isContinuingDisconnected:
                    connectionState.isContinuingDisconnected,
                isConnecting: connectionState.isConnecting,
                serverRequestPending: connectionState.serverRequestPending,
                onCancel: () =>
                    ref.read(eldConnectionProvider.notifier).cancelConnection(),
                onContinueDisconnected: () => ref
                    .read(eldConnectionProvider.notifier)
                    .continueDisconnected(),
              ),
          ],
        ),
      ),
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
    return _friendlyConnectionError(context, state.error, _macController.text);
  }

  /// SRS 9.3 #9: the failure names the ELD the driver targeted
  /// («Unable to connect to ELD with MAC 44A4»), never a raw exception.
  ///
  /// الرسالة مختصرة عمداً: التعليمات التفصيلية (MAC، التركيب، الطاقة،
  /// البلوتوث، GPS) موجودة في قائمة التحقق أسفل الشاشة، فلا تُكرَّر هنا.
  String _friendlyConnectionError(
    BuildContext context,
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
      // أخطاء الشبكة/المهلة: العنوان المختصر وحده. «تحقق من الشبكة…»
      // مكرَّرة في قائمة التحقق، فلا داعي لتكرارها داخل شريط الخطأ.
      if (error is NetworkError ||
          error.code.contains('network') ||
          error.code.contains('timeout') ||
          error.code.contains('offline')) {
        return head;
      }
      return '$head ${anyErrorUserMessage(error, loc: loc)}';
    }
    return head;
  }
}

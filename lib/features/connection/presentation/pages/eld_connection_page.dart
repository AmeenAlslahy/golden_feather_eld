import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../routes.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../../vehicle/presentation/providers/vehicle_provider.dart';
import '../providers/hardware_status_provider.dart';

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
    state = state.copyWith(isConnecting: true, hasFailed: false, errorMessage: null);

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
      
      final selectedUniqueId =
          _ref.read(vehicleProvider).selectedVehicle?.uniqueId;
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
          (data) {
            state = state.copyWith(
              isConnecting: false,
              hasFailed: false,
            );
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
    required bool isArabic,
  }) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      return isArabic ? 'اكتب سبب التسجيل اليدوي.' : 'Enter a reason for manual recording.';
    }
    try {
      final result = await _ref.read(hardwareBackendProvider).setManualMode(
            enable: enable,
            reason: trimmed,
          );
      return result.fold(
        (error) => anyErrorUserMessage(error, isArabic: isArabic),
        (_) => null,
      );
    } catch (_) {
      return isArabic
          ? 'تعذر تحديث وضع التسجيل اليدوي. أعد المحاولة.'
          : 'Could not update manual recording mode. Try again.';
    }
  }

  /// `POST /eld/hardware/connect?disconnected=true`. No reason form and no duty event.
  Future<void> continueDisconnected() async {
    final online = _ref.read(isConnectedProvider).value ?? true;
    if (!online) {
      state = state.copyWith(
        isConnecting: false,
        hasFailed: false,
        errorMessage: null,
        infoMessage: 'disconnected_accepted',
      );
      return;
    }
    state = state.copyWith(
      isConnecting: true,
      hasFailed: false,
      errorMessage: null,
      infoMessage: null,
    );
    try {
      final uniqueId = _ref.read(vehicleProvider).selectedVehicle?.uniqueId;
      final result = await _ref.read(hardwareBackendProvider).connectSession(
            uniqueId: uniqueId,
            disconnected: true,
          );
      if (!mounted) return;
      result.fold(
        (error) {
          if (error is NetworkError) {
            state = state.copyWith(
              isConnecting: false,
              hasFailed: false,
              infoMessage: 'disconnected_accepted',
            );
            return;
          }
          state = state.copyWith(
            isConnecting: false,
            hasFailed: true,
            error: error,
          );
        },
        (_) => state = state.copyWith(
          isConnecting: false,
          hasFailed: false,
          infoMessage: 'disconnected_accepted',
        ),
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isConnecting: false,
          hasFailed: false,
          infoMessage: 'disconnected_accepted',
        );
      }
    }
  }
}

final eldConnectionProvider = StateNotifierProvider.autoDispose<
    EldConnectionNotifier, EldConnectionState>((ref) {
  return EldConnectionNotifier(ref);
});

class EldConnectionPage extends ConsumerStatefulWidget {
  const EldConnectionPage({super.key});

  @override
  ConsumerState<EldConnectionPage> createState() => _EldConnectionPageState();
}

class _EldConnectionPageState extends ConsumerState<EldConnectionPage> {
  final TextEditingController _macController = TextEditingController();

  @override
  void dispose() {
    _macController.dispose();
    super.dispose();
  }

  Future<void> _attemptConnection() async {
    final notifier = ref.read(eldConnectionProvider.notifier);
    await notifier.attemptConnection(_macController.text);
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

    // الانتقال للرئيسية عند النجاح
    ref.listen<EldConnectionState>(eldConnectionProvider, (previous, current) {
      if (previous != null &&
          previous.isConnecting &&
          !current.isConnecting &&
          !current.hasFailed) {
        if (current.infoMessage == 'disconnected_accepted') {
          final isArabic = Localizations.localeOf(context).languageCode == 'ar';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic
                    ? 'قبل الخادم المتابعة دون اتصال. لم يُنشأ حدث واجب محلي.'
                    : 'The server accepted disconnected mode. No local duty event was created.',
              ),
            ),
          );
        }
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
        leading: IconButton(
          icon: const Icon(Icons.compare_arrows,
              color: AppColors.surface, size: 28),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              context.go(AppRoutes.selectVehicle);
            }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.airport_shuttle_outlined,
                color: AppColors.surface),
            tooltip: Localizations.localeOf(context).languageCode == 'ar'
                ? 'اختيار المركبة'
                : 'Select vehicle',
            onPressed: () => context.push(AppRoutes.selectVehicle),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ConnectivityPanel(),
            // شريط التنبيه الأحمر
            if (connectionState.hasFailed)
              Container(
                color: AppColors.dangerRed,
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
                  if (connectionState.hasFailed) ...[
                    // عنوان قائمة التحقق
                    Text(
                      context.loc.verifyFollowingItems,
                      style: context.styles.body,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildChecklistItem(context.loc.macEnteredCorrectly),
                    _buildChecklistItem(context.loc.hardwareProperlyInstalled),
                    _buildChecklistItem(context.loc.vehiclePowerOn),
                    _buildChecklistItem(context.loc.bluetoothEnabled),
                    _buildChecklistItem(context.loc.gpsEnabled),
                    const SizedBox(height: AppSpacing.lg),
                    Divider(color: Theme.of(context).dividerColor, height: 1),
                    const SizedBox(height: AppSpacing.lg),
                  ] else ...[
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  const _ManualRecordingSection(),

                  // عنوان حقل MAC
                  Text(
                    context.loc.enterMacAddress,
                    style: context.styles.body,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ✅ حقل إدخال موحد
                  AppTextField(
                    controller: _macController,
                    hint: 'AA:BB:CC:DD:EE:FF',
                    isUnderlined: true,
                    keyboardType: TextInputType.text,
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final target = mac.trim();
    final head = target.isEmpty
        ? (isArabic ? 'تعذر الاتصال بجهاز ELD.' : 'Unable to connect to the ELD.')
        : '${context.loc.unableToConnect} $target.';
    if (error != null) {
      return '$head ${anyErrorUserMessage(error, isArabic: isArabic)}';
    }
    if (raw == 'bluetooth_failed') {
      return isArabic
          ? '$head تحقق من تشغيل الجهاز والبلوتوث ثم أعد المحاولة.'
          : '$head Check that the device and Bluetooth are on, then try again.';
    }
    return isArabic
        ? '$head تحقق من الشبكة والجهاز ثم أعد المحاولة.'
        : '$head Check the network and device, then try again.';
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        left: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ نقطة بسيطة بدلاً من CircleAvatar
          const Padding(
            padding: EdgeInsets.only(top: 8.0, right: AppSpacing.sm),
            child: Icon(
              Icons.circle,
              size: 6,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: context.styles.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectivityPanel extends ConsumerWidget {
  const _ConnectivityPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final status = ref.watch(hardwareStatusProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: status.when(
        loading: () => Text(
          isArabic ? 'جارٍ قراءة حالة الاتصال...' : 'Reading connection status...',
          style: context.styles.body,
        ),
        error: (error, _) => Text(
          anyErrorUserMessage(error, isArabic: isArabic),
          style: context.styles.error,
        ),
        data: (data) => _statusBody(context, data, isArabic),
      ),
    );
  }

  Widget _statusBody(BuildContext context, ConnectivityStatus data, bool isArabic) {
    final lines = <String>[
      _statusLine(data, isArabic),
      if (data.hasDiagnostic)
        isArabic
            ? 'تشخيص: ${data.diagnostics.join(', ')}'
            : 'Diagnostic: ${data.diagnostics.join(', ')}',
      if (data.malfunctions.isNotEmpty)
        isArabic
            ? 'عطل: ${data.malfunctions.join(', ')}'
            : 'Malfunction: ${data.malfunctions.join(', ')}',
      if (data.lastHeartbeat != null && data.lastHeartbeat!.isNotEmpty)
        isArabic
            ? 'آخر بيانات صالحة: ${data.lastHeartbeat}'
            : 'Last valid data: ${data.lastHeartbeat}',
      if (data.dataAgeSeconds != null)
        isArabic
            ? 'عمر البيانات: ${data.dataAgeSeconds} ثانية'
            : 'Data age: ${data.dataAgeSeconds} seconds',
      if (data.normalOperationAllowed == false)
        isArabic ? 'غير جاهز للتشغيل الطبيعي.' : 'Not ready for normal operation.',
      if (data.isReliable == false)
        isArabic ? 'البيانات غير موثوقة.' : 'Data is not reliable.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(line, style: context.styles.body),
          ),
      ],
    );
  }

  String _statusLine(ConnectivityStatus data, bool isArabic) {
    switch (data.connectionStatus?.toUpperCase()) {
      case 'CONNECTED':
        return isArabic ? 'متصل' : 'Connected';
      case 'DISCONNECTED':
        return isArabic ? 'غير متصل' : 'Disconnected';
      case 'UNAVAILABLE':
        return isArabic ? 'غير متاح' : 'Unavailable';
      case 'MALFUNCTION':
        return isArabic ? 'عطل' : 'Malfunction';
      case null:
        return isArabic
            ? 'الخادم لم يُرجع حالة اتصال.'
            : 'The server did not return a connection status.';
      default:
        return data.connectionStatus!;
    }
  }
}

/// §395.34 instructions and the manual-recording toggle.
/// Shown only when the server reports a non-connected state or the connect attempt failed.
class _ManualRecordingSection extends ConsumerWidget {
  const _ManualRecordingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final status = ref.watch(hardwareStatusProvider).asData?.value;
    final failed = ref.watch(eldConnectionProvider).hasFailed;
    final serverState = status?.connectionStatus?.toUpperCase();
    final degraded = failed ||
        status?.hasMalfunction == true ||
        serverState == 'MALFUNCTION' ||
        serverState == 'DISCONNECTED' ||
        serverState == 'UNAVAILABLE';
    if (!degraded) return const SizedBox.shrink();

    final steps = isArabic
        ? const [
            'دوّن العطل وأبلغ الناقل كتابياً خلال 24 ساعة.',
            'أعد بناء سجل 24 ساعة الحالية والأيام السبعة السابقة على الورق إن لم تكن متاحة من الجهاز.',
            'استمر بالتسجيل الورقي حتى إصلاح الجهاز.',
          ]
        : const [
            'Note the malfunction and notify the carrier in writing within 24 hours.',
            'Reconstruct the current 24 hours and the previous 7 days on paper if the ELD cannot provide them.',
            'Continue paper logs until the device is repaired.',
          ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'في حال العطل (§395.34)' : 'If the ELD malfunctions (§395.34)',
            style: context.styles.body,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final step in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: AppSpacing.sm),
              child: Text('• $step', style: context.styles.subtitle),
            ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: isArabic ? 'بدء التسجيل اليدوي' : 'START MANUAL RECORDING',
            type: EldButtonType.dark,
            onPressed: () => _promptManualMode(context, ref, isArabic),
          ),
        ],
      ),
    );
  }

  Future<void> _promptManualMode(
    BuildContext context,
    WidgetRef ref,
    bool isArabic,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _ManualModeReasonDialog(isArabic: isArabic),
    );
    if (reason == null || !context.mounted) return;

    final error = await ref.read(eldConnectionProvider.notifier).setManualMode(
          enable: true,
          reason: reason,
          isArabic: isArabic,
        );
    if (!context.mounted) return;
    if (error == null) ref.invalidate(hardwareStatusProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              (isArabic
                  ? 'تم تسجيل بداية فترة التسجيل اليدوي على الخادم.'
                  : 'Manual recording start was recorded on the server.'),
        ),
      ),
    );
  }
}

/// Owns its text controller so it is disposed with the route, after the
/// dialog's exit animation — not while the TextField is still attached.
class _ManualModeReasonDialog extends StatefulWidget {
  const _ManualModeReasonDialog({required this.isArabic});

  final bool isArabic;

  @override
  State<_ManualModeReasonDialog> createState() => _ManualModeReasonDialogState();
}

class _ManualModeReasonDialogState extends State<_ManualModeReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = widget.isArabic;
    return AlertDialog(
      title: Text(isArabic ? 'سبب التسجيل اليدوي' : 'Manual recording reason'),
      content: TextField(
        controller: _controller,
        maxLines: 2,
        decoration: InputDecoration(
          hintText: isArabic
              ? 'مثال: انقطاع الاتصال بالجهاز'
              : 'e.g. lost connection to the ELD',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isArabic ? 'إلغاء' : 'CANCEL'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(isArabic ? 'موافق' : 'OK'),
        ),
      ],
    );
  }
}

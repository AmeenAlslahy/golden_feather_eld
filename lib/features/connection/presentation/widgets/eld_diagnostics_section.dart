import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../pages/eld_connection_page.dart';
import '../providers/hardware_status_provider.dart';

/// Server-side ELD connectivity status lines (SRS 3.8 diagnostics).
class EldConnectivityPanel extends ConsumerWidget {
  const EldConnectivityPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final status = ref.watch(hardwareStatusProvider);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
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

/// `GET /eld/hardware/readiness` checklist (SRS 3.3 readiness states).
///
/// Server-owned checks are shown one per line with ✓/✗, followed by the
/// server's rejection reasons and recommended action verbatim (they are the
/// authoritative text — the app does not rephrase them).
class EldReadinessPanel extends ConsumerWidget {
  const EldReadinessPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final readiness = ref.watch(hardwareReadinessProvider);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'جاهزية ما قبل التشغيل' : 'Pre-operation readiness',
            style: context.styles.bodyBold,
          ),
          const SizedBox(height: AppSpacing.xs),
          readiness.when(
            loading: () => Text(
              isArabic ? 'جارٍ فحص الجاهزية...' : 'Checking readiness...',
              style: context.styles.body,
            ),
            error: (error, _) => Text(
              anyErrorUserMessage(error, isArabic: isArabic),
              style: context.styles.error,
            ),
            data: (data) => _body(context, data, isArabic),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, HardwareReadiness data, bool isArabic) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.ready
              ? (isArabic ? 'جاهز للتشغيل' : 'Ready for operation')
              : (isArabic ? 'غير جاهز للتشغيل' : 'Not ready for operation'),
          style: data.ready ? context.styles.success : context.styles.error,
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final entry in data.checklist.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                Icon(
                  entry.value ? Icons.check_circle : Icons.cancel,
                  size: 18,
                  color: entry.value ? AppColors.successText : colors.error,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    readinessCheckLabel(entry.key, isArabic: isArabic),
                    style: context.styles.body,
                  ),
                ),
              ],
            ),
          ),
        if (data.rejectionReasons.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          for (final reason in data.rejectionReasons)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: AppSpacing.sm),
              child: Text('• $reason', style: context.styles.subtitle),
            ),
        ],
        if (data.recommendedAction != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            isArabic
                ? 'الإجراء المقترح: ${data.recommendedAction}'
                : 'Recommended action: ${data.recommendedAction}',
            style: context.styles.body,
          ),
        ],
      ],
    );
  }
}

/// Human label for a server checklist key; unknown keys are shown as-is
/// (underscores → spaces) rather than dropped.
String readinessCheckLabel(String key, {required bool isArabic}) {
  switch (key) {
    case 'device_paired':
      return isArabic ? 'الجهاز مقترن' : 'Device paired';
    case 'connection_active':
      return isArabic ? 'الاتصال نشط' : 'Connection active';
    case 'motion_data':
      return isArabic ? 'بيانات الحركة' : 'Motion data';
    case 'location_data':
      return isArabic ? 'بيانات الموقع' : 'Location data';
    case 'engine_telemetry':
      return isArabic ? 'بيانات المحرك (ECM)' : 'Engine telemetry (ECM)';
    default:
      return key.replaceAll('_', ' ');
  }
}

/// §395.34 instructions and the manual-recording toggle (SRS 3.7).
///
/// Lives on the About / Diagnostics screen (SRS 3.8): the reference
/// connection screen (screenshot 33) carries only the checklist, the MAC
/// field and the two buttons. Shown only when the server reports a
/// non-connected state, the last connect attempt failed, or manual mode is
/// already active (it must always be possible to end it — the server keeps
/// `ready=false` until the driver ends manual mode explicitly).
///
/// Server contract is a single driver-level toggle (`manual-mode`
/// `{enable, reason}`); SRS 7.14's per-malfunction "Manual RODS" cannot be
/// modelled until the server exposes malfunction entities.
class ManualRecordingSection extends ConsumerWidget {
  const ManualRecordingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final status = ref.watch(hardwareStatusProvider).asData?.value;
    final failed = ref.watch(eldConnectionProvider).hasFailed;
    final serverState = status?.connectionStatus?.toUpperCase();
    final manualActive = status?.manualModeActive == true;
    final degraded = failed ||
        status?.hasMalfunction == true ||
        serverState == 'MALFUNCTION' ||
        serverState == 'DISCONNECTED' ||
        serverState == 'UNAVAILABLE';
    if (!degraded && !manualActive) return const SizedBox.shrink();

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
          if (manualActive) ...[
            Text(
              isArabic
                  ? 'التسجيل اليدوي مفعّل حالياً${status?.manualModeReason != null ? ' — ${status!.manualModeReason}' : ''}.'
                  : 'Manual recording is active${status?.manualModeReason != null ? ' — ${status!.manualModeReason}' : ''}.',
              style: context.styles.warning,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: isArabic ? 'إنهاء التسجيل اليدوي' : 'END MANUAL RECORDING',
              type: EldButtonType.dark,
              onPressed: () => _promptManualMode(context, ref, isArabic, enable: false),
            ),
          ] else if (status?.manualRecordingAllowed == false)
            Text(
              isArabic
                  ? 'الخادم لا يسمح بالتحويل إلى التسجيل اليدوي لهذه المركبة.'
                  : 'The server does not allow manual recording for this vehicle.',
              style: context.styles.error,
            )
          else
            AppButton(
              label: isArabic ? 'بدء التسجيل اليدوي' : 'START MANUAL RECORDING',
              type: EldButtonType.dark,
              onPressed: () => _promptManualMode(context, ref, isArabic, enable: true),
            ),
        ],
      ),
    );
  }

  /// Both directions go through `POST /eld/hardware/manual-mode`, which
  /// requires a reason for enable **and** disable (400 otherwise).
  Future<void> _promptManualMode(
    BuildContext context,
    WidgetRef ref,
    bool isArabic, {
    required bool enable,
  }) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _ManualModeReasonDialog(isArabic: isArabic, enable: enable),
    );
    if (reason == null || !context.mounted) return;

    final error = await ref.read(eldConnectionProvider.notifier).setManualMode(
          enable: enable,
          reason: reason,
          isArabic: isArabic,
        );
    if (!context.mounted) return;
    if (error == null) {
      ref.invalidate(hardwareStatusProvider);
      ref.invalidate(hardwareReadinessProvider);
    }
    if (error != null) {
      AppFeedback.error(context, error);
    } else if (enable) {
      AppFeedback.success(
        context,
        isArabic
            ? 'تم تسجيل بداية فترة التسجيل اليدوي على الخادم.'
            : 'Manual recording start was recorded on the server.',
      );
    } else {
      AppFeedback.success(
        context,
        isArabic
            ? 'تم إنهاء التسجيل اليدوي والعودة إلى التسجيل الإلكتروني.'
            : 'Manual recording ended; electronic recording resumed.',
      );
    }
  }
}

/// Owns its text controller so it is disposed with the route, after the
/// dialog's exit animation — not while the TextField is still attached.
class _ManualModeReasonDialog extends StatefulWidget {
  const _ManualModeReasonDialog({required this.isArabic, required this.enable});

  final bool isArabic;
  final bool enable;

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
    final enable = widget.enable;
    return AlertDialog(
      title: Text(
        enable
            ? (isArabic ? 'سبب التسجيل اليدوي' : 'Manual recording reason')
            : (isArabic ? 'سبب إنهاء التسجيل اليدوي' : 'Reason for ending manual recording'),
      ),
      content: TextField(
        controller: _controller,
        maxLines: 2,
        decoration: InputDecoration(
          hintText: enable
              ? (isArabic
                  ? 'مثال: انقطاع الاتصال بالجهاز'
                  : 'e.g. lost connection to the ELD')
              : (isArabic
                  ? 'مثال: عاد اتصال الجهاز'
                  : 'e.g. ELD connection restored'),
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

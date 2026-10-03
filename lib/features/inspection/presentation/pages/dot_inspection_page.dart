import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../domain/inspection/dot_inspection.dart';
import '../../../account/presentation/providers/account_provider.dart';
import '../../../codriver/presentation/providers/codriver_provider.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../providers/dot_inspection_providers.dart';
import '../providers/inspection_provider.dart';
import '../widgets/inspection_duty_graph.dart';
import '../widgets/inspection_events_table.dart';
import '../widgets/inspection_log_header_table.dart';
import 'send_logs_page.dart';

/// سياسة عرض نصوص التوجيه (SRS 8.1): نصوص الخادم إنجليزية فقط — في
/// العربية تُعرض الترجمة المحلية، وفي الإنجليزية نص الخادم إن وُجد
/// وإلا الترجمة المحلية. دالة صرفة قابلة للاختبار بلا widget.
String inspectionDisplayText({
  required bool isArabic,
  required String? serverText,
  required String localFallback,
}) {
  final value = serverText?.trim() ?? '';
  return (isArabic || value.isEmpty) ? localFallback : value;
}

/// شاشة DOT Inspection — غلاف رقيق: يقرر أي عرض يُبنى ويمتلك بوابة
/// البدء/الخروج (حوارا PIN)؛ العرضان أنفسهما أدناه.
class DotInspectionPage extends ConsumerStatefulWidget {
  const DotInspectionPage({super.key});

  @override
  ConsumerState<DotInspectionPage> createState() => _DotInspectionPageState();
}

class _DotInspectionPageState extends ConsumerState<DotInspectionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accountProvider.notifier).fetchMyAccount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inspectionProvider);
    final locked = state.isInspectionMode && state.isPinLocked;

    return PopScope(
      canPop: !locked,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && locked) {
          _promptDriverExit();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: !locked,
          title: Text(
            context.loc.dotInspection,
            style: context.styles.appBarTitle,
          ),
          leading: locked
              ? IconButton(
                  icon: const Icon(Icons.lock),
                  onPressed: _promptDriverExit,
                )
              : Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
        ),
        drawer: locked ? null : const EldDrawer(),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : !state.isInspectionMode
            ? InspectionStartView(onStartInspection: _startWithPin)
            : InspectionActiveView(
                state: state,
                onExitRequest: _promptDriverExit,
              ),
      ),
    );
  }

  Future<void> _startWithPin() async {
    final pin = await _askNewPin();
    if (pin == null || !mounted) return;
    await ref.read(inspectionProvider.notifier).startInspection(pin: pin);
  }

  Future<String?> _askNewPin() {
    // The dialog owns its controllers: disposing them right after
    // `showDialog` returns throws during the exit animation.
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _InspectionPinDialog(),
    );
  }

  Future<void> _promptDriverExit() {
    // الخروج يتم داخل الحوار عبر exitWithPin — الحالة تعاد كاملة
    // وإعادة البناء تجري من تلقاء نفسها.
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DriverExitDialog(),
    );
  }
}

// =============================================================================
// عرض البداية — الإرشاد + الصلاحيات الأربع من الخادم (fail-closed)
// =============================================================================

class InspectionStartView extends ConsumerWidget {
  const InspectionStartView({super.key, required this.onStartInspection});

  /// بوابة الدخول: حوار PIN ثم startInspection — يملكها الصفحة الأم.
  final VoidCallback onStartInspection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenAsync = ref.watch(dotInspectionScreenProvider);
    final lifecycleError = ref.watch(inspectionProvider.select((s) => s.error));
    final screen = screenAsync.asData?.value;
    final loc = context.loc;
    final isArabic = context.isArabic;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (lifecycleError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Text(
              lifecycleError,
              textAlign: TextAlign.center,
              style: context.styles.error,
            ),
          ),
        if (screenAsync.hasError)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              children: [
                Text(
                  context.loc.errRequestFailed,
                  textAlign: TextAlign.center,
                  style: context.styles.error,
                ),
                TextButton(
                  onPressed: () => ref.invalidate(dotInspectionScreenProvider),
                  child: Text(context.loc.retryAction),
                ),
              ],
            ),
          ),
        InspectionActionSection(
          title: inspectionDisplayText(
            isArabic: isArabic,
            serverText: screen?.guidanceText,
            localFallback: loc.inspectLogs24,
          ),
          description: inspectionDisplayText(
            isArabic: isArabic,
            serverText: screen?.handOverDeviceNotice,
            localFallback: loc.setPinGuidance,
          ),
          buttonLabel: loc.startInspectionUpper,
          enabled: screen?.canStartInspection ?? false,
          disabledMessage: loc.serverDoesNotAllow,
          onPressed: onStartInspection,
        ),
        const Divider(height: 1, thickness: 1),
        InspectionActionSection(
          title: loc.sendLogsFor24,
          description: loc.sendLogsToOfficer,
          buttonLabel: loc.sendLogsUpper,
          enabled: screen?.canSendLogs ?? false,
          disabledMessage: loc.notAllowedByServer,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SendLogsPage()),
          ),
        ),
        const Divider(height: 1, thickness: 1),
        InspectionActionSection(
          title: loc.emailLogs24Pdf,
          description: loc.emailLogsPdf,
          buttonLabel: loc.emailLogsUpper,
          enabled: screen?.canEmailLogs ?? false,
          disabledMessage: loc.notAllowedByServer,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SendLogsPage(isEmailMode: true),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1),
        InspectionActionSection(
          title: inspectionDisplayText(
            isArabic: isArabic,
            serverText: screen?.carrierComplianceStatement,
            localFallback: loc.eldCertifies,
          ),
          buttonLabel: loc.infoPacketUpper,
          enabled: screen?.canViewInformationPacket ?? false,
          disabledMessage: loc.notAllowedByServer,
          onPressed: () => context.push(AppRoutes.infoPacket),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

/// قسم إجراء واحد في عرض البداية: عنوان + وصف اختياري + زر + رسالة رفض
/// عند تعطيل الزر. (كانت أربعة أقسام مكررة يدوياً.)
class InspectionActionSection extends StatelessWidget {
  const InspectionActionSection({
    super.key,
    required this.title,
    required this.buttonLabel,
    required this.enabled,
    required this.onPressed,
    this.description,
    this.disabledMessage,
  });

  final String title;
  final String? description;
  final String buttonLabel;
  final bool enabled;
  final VoidCallback? onPressed;
  final String? disabledMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: context.styles.body),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: context.styles.muted,
            ),
          ],
          const SizedBox(height: 16),
          AppButton(
            label: buttonLabel,
            type: EldButtonType.dark,
            onPressed: enabled ? onPressed : null,
          ),
          if (!enabled && disabledMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              disabledMessage!,
              textAlign: TextAlign.center,
              style: context.styles.muted,
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// عرض التفتيش النشط — محمي بـ PIN؛ التاريخ والسجل زوج ذري من الحالة
// =============================================================================

DotInspectionCycleDay? _selectedCycleDay(InspectionState state) {
  final index = state.selectedDayIndex;
  if (index < 0 || index >= state.cycle.length) return null;
  return state.cycle[index];
}

class InspectionActiveView extends ConsumerWidget {
  const InspectionActiveView({
    super.key,
    required this.state,
    required this.onExitRequest,
  });

  final InspectionState state;
  final VoidCallback onExitRequest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = state.log;
    final day = _selectedCycleDay(state);
    final account = ref.watch(accountProvider).accountData;
    final co = ref.watch(codriverProvider).currentCoDriver;
    // dayError خاص بتحميل اليوم؛ error lifecycle/بدء فقط — الأولوية
    // لخطأ اليوم في هذه الشاشة حتى لا يضيع خلف رسالة أقدم.
    final bannerError = state.dayError ?? state.error;

    return Column(
      children: [
        if (bannerError != null)
          Material(
            color: AppColors.warningYellow.withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                bannerError,
                textAlign: TextAlign.center,
                style: context.styles.warning,
              ),
            ),
          ),
        _DaySelector(state: state),
        const Divider(height: 1),
        Expanded(
          child: log == null
              ? Center(
                  child: Text(
                    state.error ?? context.loc.noData,
                    textAlign: TextAlign.center,
                    style: state.error != null
                        ? context.styles.error
                        : context.styles.muted,
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      InspectionLogHeaderTable(
                        log: log,
                        day: day,
                        driverLicense: account?.license.number ?? '-',
                        driverLicenseState: account?.license.state ?? '-',
                        coDriver: co?.name ?? '',
                        coDriverId: co?.isLinked == true
                            ? '${co!.coDriverId}'
                            : '',
                      ),
                      const Divider(height: 1),
                      InspectionDutyGraph(events: log.events),
                      const Divider(height: 1),
                      InspectionEventsTable(events: log.events),
                      const SizedBox(height: AppSpacing.lg),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AppButton(
                          label: context.loc.driverExit,
                          type: EldButtonType.danger,
                          onPressed: onExitRequest,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// شريط التنقل بين أيام الدورة — السهمان يعطلان أثناء أي تحميل يوم،
/// والتاريخ لا يتقدم قبل نجاح الطلب (الالتزام الذري في الـ notifier).
class _DaySelector extends ConsumerWidget {
  const _DaySelector({required this.state});

  final InspectionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = _selectedCycleDay(state);
    return Container(
      color: AppColors.primaryGold.withValues(alpha: 0.05),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                state.isDayLoading ||
                    state.selectedDayIndex >= state.cycle.length - 1
                ? null
                : () => ref
                      .read(inspectionProvider.notifier)
                      .selectDay(state.selectedDayIndex + 1),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                day?.displayDate.isNotEmpty == true
                    ? day!.displayDate
                    : (state.log?.displayDate ?? ''),
                key: const Key('inspection-day-label'),
                style: context.styles.bodyBold,
              ),
              if (state.isDayLoading) ...[
                const SizedBox(width: AppSpacing.sm),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: state.isDayLoading || state.selectedDayIndex <= 0
                ? null
                : () => ref
                      .read(inspectionProvider.notifier)
                      .selectDay(state.selectedDayIndex - 1),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// حوارا PIN (SRS 7.5)
// =============================================================================

/// Sets the 4-digit inspection PIN (SRS 7.5). Pops with the PIN or null.
class _InspectionPinDialog extends StatefulWidget {
  const _InspectionPinDialog();

  @override
  State<_InspectionPinDialog> createState() => _InspectionPinDialogState();
}

class _InspectionPinDialogState extends State<_InspectionPinDialog> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_pin.text.length != 4) {
      setState(() {
        _error = context.loc.enter4Digits;
      });
      return;
    }
    if (_pin.text != _confirm.text) {
      setState(() {
        _error = context.loc.pinsDoNotMatch;
      });
      return;
    }
    Navigator.pop(context, _pin.text);
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return AlertDialog(
      title: Text(loc.inspectionPinTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.setPinGuidanceDialog, style: context.styles.muted),
            const SizedBox(height: 12),
            AppTextField(
              controller: _pin,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              label: context.loc.pinLabel,
            ),
            AppTextField(
              controller: _confirm,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              label: context.loc.confirmPinLabel,
              onSubmitted: (_) => _submit(context),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: context.styles.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.loc.cancelAction),
        ),
        TextButton(
          onPressed: () => _submit(context),
          child: Text(context.loc.startAction),
        ),
      ],
    );
  }
}

/// Exit gate for inspection mode (SRS 7.5): the driver re-enters the PIN he
/// composed when the inspection started. Checked locally against the PIN held
/// in `inspectionProvider` — no network call, no lockout: the driver must
/// always be able to leave at the roadside, and the login password is never
/// re-sent to the server.
class _DriverExitDialog extends ConsumerStatefulWidget {
  const _DriverExitDialog();

  @override
  ConsumerState<_DriverExitDialog> createState() => _DriverExitDialogState();
}

class _DriverExitDialogState extends ConsumerState<_DriverExitDialog> {
  final _pin = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final pin = _pin.text.trim();
    if (pin.isEmpty) {
      setState(() {
        _error = context.loc.enterInspectionPin;
      });
      return;
    }
    final accepted = ref.read(inspectionProvider.notifier).exitWithPin(pin);
    if (!accepted) {
      setState(() {
        _error = context.loc.incorrectPin;
      });
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.loc.driverExit),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.loc.enterPinToExitGuidance,
              style: context.styles.muted,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _pin,
              obscureText: true,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              label: context.loc.pinLabel,
              onSubmitted: (_) => _submit(context),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: context.styles.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.loc.cancelAction),
        ),
        TextButton(
          onPressed: () => _submit(context),
          child: Text(context.loc.exitAction),
        ),
      ],
    );
  }
}

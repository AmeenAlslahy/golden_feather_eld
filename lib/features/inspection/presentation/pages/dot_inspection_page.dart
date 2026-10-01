import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../account/presentation/providers/account_provider.dart';
import '../../../codriver/presentation/providers/codriver_provider.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../providers/dot_inspection_providers.dart';
import '../providers/inspection_provider.dart';
import '../widgets/inspection_duty_graph.dart';
import '../widgets/inspection_events_table.dart';
import '../widgets/inspection_log_header_table.dart';
import 'send_logs_page.dart';

/// شاشة DOT Inspection
class DotInspectionPage extends ConsumerStatefulWidget {
  const DotInspectionPage({super.key});

  @override
  ConsumerState<DotInspectionPage> createState() => _DotInspectionPageState();
}

class _DotInspectionPageState extends ConsumerState<DotInspectionPage> {
  int _currentDayIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accountProvider.notifier).fetchMyAccount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inspectionState = ref.watch(inspectionProvider);
    final locked = inspectionState.isInspectionMode && inspectionState.isPinLocked;

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
        body: inspectionState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : !inspectionState.isInspectionMode
                ? _buildStartInspection()
                : _buildInspectionView(inspectionState),
      ),
    );
  }

  Widget _buildStartInspection() {
    final error = ref.watch(inspectionProvider).error;
    final screen = ref.watch(dotInspectionScreenProvider).asData?.value;
    // نصوص الخادم إنجليزية فقط: في العربية نعرض الترجمات المحلية،
    // وفي الإنجليزية نعرض نص الخادم (SRS 8.1: الخادم يخصص الإرشاد).
    final useLocalText = context.isArabic;
    String serverOrLocal(String? serverText, String local) {
      final v = serverText?.trim() ?? '';
      return (useLocalText || v.isEmpty) ? local : v;
    }

    final guidance = serverOrLocal(
        screen?.guidanceText, context.loc.inspectLogs24);
    final handOver = serverOrLocal(
        screen?.handOverDeviceNotice, context.loc.setPinGuidance);
    final compliance = serverOrLocal(
        screen?.carrierComplianceStatement, context.loc.eldCertifies);
    final canStart = screen?.canStartInspection ?? true;
    final canSend = screen?.canSendLogs ?? true;
    final canEmail = screen?.canEmailLogs ?? true;
    final canPacket = screen?.canViewInformationPacket ?? true;
    final notAllowed = context.loc.notAllowedByServer;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(error,
                      textAlign: TextAlign.center, style: context.styles.error),
                ),
              Text(
                guidance,
                textAlign: TextAlign.center,
                style: context.styles.body,
              ),
              const SizedBox(height: 8),
              Text(
                handOver,
                textAlign: TextAlign.center,
                style: context.styles.muted,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: context.loc.startInspectionUpper,
                type: EldButtonType.dark,
                onPressed: canStart ? _startWithPin : null,
              ),
              if (!canStart) ...[
                const SizedBox(height: 8),
                Text(
                  context.loc.serverDoesNotAllow,
                  textAlign: TextAlign.center,
                  style: context.styles.muted,
                ),
              ],
            ],
          ),
        ),
        
        const Divider(height: 1, thickness: 1),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              Text(
                context.loc.sendLogsFor24,
                textAlign: TextAlign.center,
                style: context.styles.body,
              ),
              const SizedBox(height: 8),
              Text(
                context.loc.sendLogsToOfficer,
                textAlign: TextAlign.center,
                style: context.styles.muted,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: context.loc.sendLogsUpper,
                type: EldButtonType.dark,
                onPressed: canSend
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SendLogsPage()),
                        );
                      }
                    : null,
              ),
              if (!canSend) ...[
                const SizedBox(height: 8),
                Text(notAllowed,
                    textAlign: TextAlign.center, style: context.styles.muted),
              ],
            ],
          ),
        ),
        
        const Divider(height: 1, thickness: 1),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              Text(
                context.loc.emailLogs24Pdf,
                textAlign: TextAlign.center,
                style: context.styles.body,
              ),
              const SizedBox(height: 8),
              Text(
                context.loc.emailLogsPdf,
                textAlign: TextAlign.center,
                style: context.styles.muted,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: context.loc.emailLogsUpper,
                type: EldButtonType.dark,
                onPressed: canEmail
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const SendLogsPage(isEmailMode: true),
                          ),
                        );
                      }
                    : null,
              ),
              if (!canEmail) ...[
                const SizedBox(height: 8),
                Text(notAllowed,
                    textAlign: TextAlign.center, style: context.styles.muted),
              ],
            ],
          ),
        ),
        
        const Divider(height: 1, thickness: 1),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              Text(
                compliance,
                textAlign: TextAlign.center,
                style: context.styles.body,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: context.loc.infoPacketUpper,
                type: EldButtonType.dark,
                onPressed: canPacket
                    ? () => context.push(AppRoutes.infoPacket)
                    : null,
              ),
              if (!canPacket) ...[
                const SizedBox(height: 8),
                Text(notAllowed,
                    textAlign: TextAlign.center, style: context.styles.muted),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildInspectionView(InspectionState state) {
    final log = state.log;
    final day = _currentDayIndex >= 0 && _currentDayIndex < state.cycle.length
        ? state.cycle[_currentDayIndex]
        : null;
    final loc = context.loc;
    final account = ref.watch(accountProvider).accountData;
    final co = ref.watch(codriverProvider).currentCoDriver;
    return Column(
      children: [
        if (state.error != null)
          Material(
            color: AppColors.warningYellow.withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(state.error!,
                  textAlign: TextAlign.center, style: context.styles.warning),
            ),
          ),
        Container(
          color: AppColors.primaryGold.withValues(alpha: 0.05),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentDayIndex < state.cycle.length - 1
                    ? () {
                        final next = _currentDayIndex + 1;
                        if (next >= state.cycle.length) return;
                        setState(() => _currentDayIndex = next);
                        ref
                            .read(inspectionProvider.notifier)
                            .loadLog(state.cycle[next].logDate);
                      }
                    : null,
              ),
              Text(
                day?.displayDate.isNotEmpty == true
                    ? day!.displayDate
                    : (log?.displayDate ?? ''),
                style: context.styles.bodyBold,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentDayIndex > 0
                    ? () {
                        final next = _currentDayIndex - 1;
                        if (next < 0) return;
                        setState(() => _currentDayIndex = next);
                        ref
                            .read(inspectionProvider.notifier)
                            .loadLog(state.cycle[next].logDate);
                      }
                    : null,
              ),
            ],
          ),
        ),
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
                        coDriverId:
                            co?.isLinked == true ? '${co!.coDriverId}' : '',
                      ),
                      const Divider(height: 1),
                      InspectionDutyGraph(events: log.events),
                      const Divider(height: 1),
                      InspectionEventsTable(events: log.events),
                      const SizedBox(height: AppSpacing.lg),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AppButton(
                          label: loc.driverExit,
                          type: EldButtonType.danger,
                          onPressed: _promptDriverExit,
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

  Future<void> _startWithPin() async {
    final pin = await _askNewPin();
    if (pin == null || !mounted) return;
    await ref.read(inspectionProvider.notifier).startInspection(pin: pin);
    if (!mounted) return;
    setState(() => _currentDayIndex = 0);
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

  Future<void> _promptDriverExit() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DriverExitDialog(),
    );
    if (ok == true && mounted) {
      setState(() => _currentDayIndex = 0);
    }
  }
}

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
            Text(
              loc.setPinGuidanceDialog,
              style: context.styles.muted,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pin,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: context.loc.pinLabel,
                counterText: '',
              ),
            ),
            TextField(
              controller: _confirm,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _submit(context),
              decoration: InputDecoration(
                labelText: context.loc.confirmPinLabel,
                counterText: '',
              ),
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
/// in `inspectionProvider` — no network call, so the driver can always leave
/// at the roadside, and the login password is never re-sent to the server.
class _DriverExitDialog extends ConsumerStatefulWidget {
  const _DriverExitDialog();

  @override
  ConsumerState<_DriverExitDialog> createState() => _DriverExitDialogState();
}

class _DriverExitDialogState extends ConsumerState<_DriverExitDialog> {
  final _pin = TextEditingController();
  String? _error;
  int _failedAttempts = 0;
  static const _maxAttempts = 5;

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
      _failedAttempts++;
      setState(() {
        _error = _failedAttempts >= _maxAttempts
            ? context.loc.tooManyPinAttempts
            : context.loc.incorrectPin;
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
            TextField(
              controller: _pin,
              obscureText: true,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _submit(context),
              decoration: InputDecoration(
                labelText: context.loc.pinLabel,
                counterText: '',
              ),
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



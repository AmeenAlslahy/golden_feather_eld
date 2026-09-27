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
                  icon: const Icon(Icons.lock, color: AppColors.surface),
                  onPressed: _promptDriverExit,
                )
              : Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.surface),
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final error = ref.watch(inspectionProvider).error;
    // Live GET /eld/dot-inspection. Server text wins when present; local copy is the fallback.
    final screen = ref.watch(dotInspectionScreenProvider).asData?.value;
    final guidance = _nonEmpty(screen?.guidanceText) ??
        (isArabic
            ? 'افحص سجلات فترة 24 ساعة والأيام السابقة لدورة واحدة'
            : 'Inspect logs for the 24-hour period and the previous days for one HOS cycle');
    final handOver = _nonEmpty(screen?.handOverDeviceNotice) ??
        (isArabic
            ? 'عيّن رمزاً ثم اختر «بدء التفتيش» وسلّم الجهاز للضابط'
            : 'Set a PIN, select "Start Inspection", and give your device to the officer');
    final compliance = _nonEmpty(screen?.carrierComplianceStatement) ??
        (isArabic
            ? 'يشهد التطبيق أن استخدامه مع الجهاز يستوفي متطلبات ELD في 49 CFR part 395 Subpart B.'
            : 'This ELD certifies that use of the app with the ELD device complies with all requirements for ELD as defined in Federal Motor Carrier Safety regulation 49 CFR part 395 Subpart B.');
    final canStart = screen?.canStartInspection ?? true;
    final canSend = screen?.canSendLogs ?? true;
    final canEmail = screen?.canEmailLogs ?? true;
    final canPacket = screen?.canViewInformationPacket ?? true;
    final notAllowed = isArabic
        ? 'غير متاح لهذا الحساب حسب الخادم.'
        : 'Not available for this account per the server.';
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
                label: isArabic ? 'بدء التفتيش' : 'START INSPECTION',
                type: EldButtonType.dark,
                onPressed: canStart ? _startWithPin : null,
              ),
              if (!canStart) ...[
                const SizedBox(height: 8),
                Text(
                  isArabic
                      ? 'الخادم لا يسمح ببدء التفتيش الآن.'
                      : 'The server does not allow starting an inspection right now.',
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
                isArabic
                    ? 'أرسل السجلات لفترة 24 ساعة والأيام السابقة لدورة واحدة'
                    : 'Send logs for the 24-hour period and the previous days for one HOS cycle',
                textAlign: TextAlign.center,
                style: context.styles.body,
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'أرسل سجلاتك للضابط إذا طلب ذلك'
                    : 'Send your logs to the officer if they request',
                textAlign: TextAlign.center,
                style: context.styles.muted,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: isArabic ? 'إرسال السجلات' : 'SEND LOGS',
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
                isArabic
                    ? 'أرسل السجلات بالبريد لفترة 24 ساعة والأيام السابقة كملف PDF'
                    : 'Email logs for the 24-hour period and the previous days for one HOS cycle as PDF',
                textAlign: TextAlign.center,
                style: context.styles.body,
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'أرسل سجلاتك بصيغة PDF'
                    : 'Email your logs in the PDF format',
                textAlign: TextAlign.center,
                style: context.styles.muted,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: isArabic ? 'بريد السجلات' : 'EMAIL LOGS',
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
                label: isArabic ? 'حزمة المعلومات' : 'INFORMATION PACKET',
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
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
                          label: isArabic
                              ? 'خروج السائق'
                              : 'DRIVER EXIT',
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

  void _submit(bool isArabic) {
    if (_pin.text.length != 4) {
      setState(() {
        _error = isArabic ? 'الرمز يجب أن يكون 4 أرقام.' : 'PIN must be 4 digits.';
      });
      return;
    }
    if (_pin.text != _confirm.text) {
      setState(() {
        _error = isArabic ? 'الرمزان غير متطابقين.' : 'The PINs do not match.';
      });
      return;
    }
    Navigator.pop(context, _pin.text);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return AlertDialog(
      title: Text(isArabic ? 'رمز التفتيش' : 'Inspection PIN'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isArabic
                  ? 'عيّن رمزاً من 4 أرقام لقفل الشاشة. المفتش يرى السجلات فقط ولا يخرج إلا بكلمة مرور السائق.'
                  : 'Set a 4-digit PIN to lock the screen. The officer can only view logs and cannot leave without the driver password.',
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
                labelText: isArabic ? 'الرمز' : 'PIN',
                counterText: '',
              ),
            ),
            TextField(
              controller: _confirm,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _submit(isArabic),
              decoration: InputDecoration(
                labelText: isArabic ? 'تأكيد الرمز' : 'Confirm PIN',
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
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        TextButton(
          onPressed: () => _submit(isArabic),
          child: Text(isArabic ? 'بدء' : 'Start'),
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

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _submit(bool isArabic) {
    final pin = _pin.text.trim();
    if (pin.isEmpty) {
      setState(() {
        _error = isArabic ? 'أدخل رمز التفتيش.' : 'Enter the inspection PIN.';
      });
      return;
    }
    final accepted = ref.read(inspectionProvider.notifier).exitWithPin(pin);
    if (!accepted) {
      setState(() {
        _error = isArabic ? 'الرمز غير صحيح.' : 'Incorrect PIN.';
      });
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return AlertDialog(
      title: Text(isArabic ? 'خروج السائق' : 'Driver exit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isArabic
                  ? 'أدخل رمز التفتيش الذي عيّنته عند البدء. المفتش لا يخرج من هنا.'
                  : 'Enter the inspection PIN you set when starting. The officer cannot leave here.',
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
              onSubmitted: (_) => _submit(isArabic),
              decoration: InputDecoration(
                labelText: isArabic ? 'الرمز' : 'PIN',
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
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        TextButton(
          onPressed: () => _submit(isArabic),
          child: Text(isArabic ? 'خروج' : 'Exit'),
        ),
      ],
    );
  }
}

String? _nonEmpty(String? value) {
  final v = value?.trim();
  return (v == null || v.isEmpty) ? null : v;
}

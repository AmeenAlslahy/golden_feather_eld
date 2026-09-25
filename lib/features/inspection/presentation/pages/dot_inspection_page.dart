import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../routes.dart';
import '../../../account/presentation/providers/account_provider.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(error, textAlign: TextAlign.center),
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
        const SizedBox(height: 28),
        const Divider(height: 1),
        const SizedBox(height: 28),
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
                    MaterialPageRoute(builder: (_) => const SendLogsPage()),
                  );
                }
              : null,
        ),
        if (!canSend) ...[
          const SizedBox(height: 8),
          Text(notAllowed, textAlign: TextAlign.center, style: context.styles.muted),
        ],
        const SizedBox(height: 28),
        const Divider(height: 1),
        const SizedBox(height: 28),
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
                      builder: (_) => const SendLogsPage(isEmailMode: true),
                    ),
                  );
                }
              : null,
        ),
        if (!canEmail) ...[
          const SizedBox(height: 8),
          Text(notAllowed, textAlign: TextAlign.center, style: context.styles.muted),
        ],
        const SizedBox(height: 28),
        const Divider(height: 1),
        const SizedBox(height: 28),
        Text(
          compliance,
          textAlign: TextAlign.center,
          style: context.styles.body,
        ),
        const SizedBox(height: 16),
        AppButton(
          label: isArabic ? 'حزمة المعلومات' : 'INFORMATION PACKET',
          type: EldButtonType.dark,
          onPressed: canPacket ? () => context.push(AppRoutes.infoPacket) : null,
        ),
        if (!canPacket) ...[
          const SizedBox(height: 8),
          Text(notAllowed, textAlign: TextAlign.center, style: context.styles.muted),
        ],
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
              child: Text(state.error!, textAlign: TextAlign.center),
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
              ? Center(child: Text(state.error ?? context.loc.noData))
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

  Future<String?> _askNewPin() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final pin = TextEditingController();
    final confirm = TextEditingController();
    String? error;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isArabic ? 'رمز التفتيش' : 'Inspection PIN',
              ),
              content: Column(
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
                    controller: pin,
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
                    controller: confirm,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: isArabic ? 'تأكيد الرمز' : 'Confirm PIN',
                      counterText: '',
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(error!, style: context.styles.error),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (pin.text.length != 4) {
                      setDialogState(() {
                        error = isArabic
                            ? 'الرمز يجب أن يكون 4 أرقام.'
                            : 'PIN must be 4 digits.';
                      });
                      return;
                    }
                    if (pin.text != confirm.text) {
                      setDialogState(() {
                        error = isArabic
                            ? 'الرمزان غير متطابقين.'
                            : 'The PINs do not match.';
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, pin.text);
                  },
                  child: Text(isArabic ? 'بدء' : 'Start'),
                ),
              ],
            );
          },
        );
      },
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      pin.dispose();
      confirm.dispose();
    });
    return result;
  }

  Future<void> _promptDriverExit() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final password = TextEditingController();
    String? error;
    var busy = false;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isArabic ? 'كلمة مرور السائق' : 'Driver password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isArabic
                        ? 'أدخل كلمة مرور حساب السائق للخروج. المفتش لا يخرج من هنا.'
                        : 'Enter the driver account password to exit. The officer cannot leave here.',
                    style: context.styles.muted,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    autofocus: true,
                    enabled: !busy,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'كلمة المرور' : 'Password',
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(error!, style: context.styles.error),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: busy
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          final user = ref.read(authStateProvider).user;
                          final identifier =
                              user?.username.trim().isNotEmpty == true
                                  ? user!.username.trim()
                                  : (user?.email.trim() ?? '');
                          if (identifier.isEmpty || password.text.isEmpty) {
                            setDialogState(() {
                              error = isArabic
                                  ? 'أدخل كلمة مرور السائق.'
                                  : 'Enter the driver password.';
                            });
                            return;
                          }
                          setDialogState(() {
                            busy = true;
                            error = null;
                          });
                          final result =
                              await ref.read(authBackendProvider).login(
                                    identifier: identifier,
                                    password: password.text,
                                    serverUrl: ref.read(serverUrlProvider),
                                    backendType: ref
                                        .read(localStorageProvider)
                                        .backendType,
                                  );
                          if (!dialogContext.mounted) return;
                          final accepted =
                              result.fold((_) => false, (_) => true);
                          if (!accepted) {
                            setDialogState(() {
                              busy = false;
                              error = isArabic
                                  ? 'كلمة المرور غير صحيحة.'
                                  : 'Incorrect password.';
                            });
                            return;
                          }
                          ref
                              .read(inspectionProvider.notifier)
                              .exitAfterDriverVerified();
                          Navigator.pop(dialogContext, true);
                        },
                  child: Text(isArabic ? 'خروج' : 'Exit'),
                ),
              ],
            );
          },
        );
      },
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      password.dispose();
    });
    if (ok == true && mounted) {
      setState(() => _currentDayIndex = 0);
    }
  }
}

String? _nonEmpty(String? value) {
  final v = value?.trim();
  return (v == null || v.isEmpty) ? null : v;
}

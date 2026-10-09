import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../account/presentation/providers/account_provider.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../providers/inspection_provider.dart';
import 'inspection_active_view.dart';
import 'inspection_start_view.dart';

/// شاشة DOT Inspection — غلاف يختار العرض ويملك بوابتَي PIN.
///
/// لا منطق هنا: الحالة تُقرأ من [inspectionProvider] (معمّرة)، والعرضان
/// يبنيان أنفسهما؛ حتى جلب الحساب يحدث عند الدخول الفعلي لوضع التفتيش
/// لا عند كل زيارة.
class DotInspectionPage extends ConsumerStatefulWidget {
  const DotInspectionPage({super.key});

  @override
  ConsumerState<DotInspectionPage> createState() => _DotInspectionPageState();
}

class _DotInspectionPageState extends ConsumerState<DotInspectionPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inspectionProvider);

    return PopScope(
      canPop: !state.locked,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && state.locked) _exitDirectly();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: !state.locked,
          title: Text(
            context.loc.dotInspection,
            style: context.styles.appBarTitle,
          ),
          leading: state.locked
              ? IconButton(
                  icon: const Icon(Icons.lock),
                  onPressed: _exitDirectly,
                )
              : Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
        ),
        drawer: state.locked ? null : const EldDrawer(),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : !state.isInspectionMode
            ? InspectionStartView(onStartInspection: _startDirectly)
            : InspectionActiveView(onExitRequest: _exitDirectly),
      ),
    );
  }

  /// بدء وضع التفتيش الميداني مباشرة بدون رمز PIN
  Future<void> _startDirectly() async {
    await ref.read(inspectionProvider.notifier).startInspection();
    if (!mounted) return;
    if (ref.read(inspectionProvider).isInspectionMode) {
      ref.read(accountProvider.notifier).fetchMyAccount();
    }
  }

  /// إنهاء وضع التفتيش والعودة مباشرة
  void _exitDirectly() {
    ref.read(inspectionProvider.notifier).endInspection();
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
    // القاعدة نفسها التي يتحقق بها الخروج — دالة نقية مشتركة.
    if (!isValidInspectionPin(_pin.text)) {
      setState(() => _error = context.loc.enter4Digits);
      return;
    }
    if (_pin.text != _confirm.text) {
      setState(() => _error = context.loc.pinsDoNotMatch);
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              label: context.loc.pinLabel,
            ),
            AppTextField(
              controller: _confirm,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
    if (!isValidInspectionPin(pin)) {
      setState(() => _error = context.loc.enterInspectionPin);
      return;
    }
    final accepted = ref.read(inspectionProvider.notifier).exitWithPin(pin);
    if (!accepted) {
      setState(() => _error = context.loc.incorrectPin);
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

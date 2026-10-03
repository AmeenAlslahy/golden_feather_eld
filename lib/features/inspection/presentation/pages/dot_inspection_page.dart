import 'package:flutter/material.dart';
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
        if (!didPop && state.locked) _promptDriverExit();
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
                  onPressed: _promptDriverExit,
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
            ? InspectionStartView(onStartInspection: _startWithPin)
            : InspectionActiveView(onExitRequest: _promptDriverExit),
      ),
    );
  }

  /// بوابة البدء: حوار PIN → startInspection → عند النجاح فقط يُجلب
  /// الحساب (احتياطي ترويسة SRS 670-675) — لا طلب عند كل زيارة.
  Future<void> _startWithPin() async {
    final pin = await _askNewPin();
    if (pin == null || !mounted) return;
    await ref.read(inspectionProvider.notifier).startInspection(pin: pin);
    if (!mounted) return;
    if (ref.read(inspectionProvider).isInspectionMode) {
      ref.read(accountProvider.notifier).fetchMyAccount();
    }
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

  /// بوابة الخروج: الحوار يستدعي exitWithPin بنفسه ويعيد الحالة كاملة؛
  /// إعادة البناء تتبعها تلقائياً.
  Future<void> _promptDriverExit() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DriverExitDialog(),
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

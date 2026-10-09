import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../account/presentation/providers/account_provider.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../providers/inspection_provider.dart';
import 'inspection_active_view.dart';
import 'inspection_start_view.dart';

/// شاشة DOT Inspection — بدء وإنهاء التفتيش مباشرة بدون رمز PIN.
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
                  icon: const Icon(Icons.arrow_back),
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

  /// إنهاء وضع التفتيش والعودة مباشرة بدون طلب رمز PIN
  void _exitDirectly() {
    ref.read(inspectionProvider.notifier).endInspection();
  }
}


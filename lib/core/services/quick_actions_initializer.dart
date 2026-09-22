import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_actions/quick_actions.dart';

import '../../features/tracking/data/services/tracking_service.dart';
import '../../l10n/app_localizations.dart';

/// مهيئ الاختصارات السريعة - من quick_actions.dart الأصلي
class QuickActionsInitializer extends ConsumerStatefulWidget {
  const QuickActionsInitializer({super.key});

  @override
  ConsumerState<QuickActionsInitializer> createState() =>
      _QuickActionsInitializerState();
}

class _QuickActionsInitializerState
    extends ConsumerState<QuickActionsInitializer> {
  final QuickActions _quickActions = const QuickActions();

  @override
  void initState() {
    super.initState();
    _quickActions.initialize((shortcutType) async {
      FirebaseCrashlytics.instance.log('quick_action: $shortcutType');

      try {
        final trackingService = ref.read(trackingServiceProvider);

        switch (shortcutType) {
          case 'start':
            await trackingService.start();
          case 'stop':
            await trackingService.stop();
          case 'sos':
            await trackingService.requestPosition(alarm: 'sos');
        }
      } on PlatformException {
        // permission denied or startup error
      }

      if (mounted) {
        FirebaseCrashlytics.instance.log('quick_action_exit');
        SystemNavigator.pop();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = AppLocalizations.of(context)!;
    _quickActions.setShortcutItems(<ShortcutItem>[
      ShortcutItem(
        type: 'start',
        localizedTitle: loc.startAction,
        icon: 'play',
      ),
      ShortcutItem(
        type: 'stop',
        localizedTitle: loc.stopAction,
        icon: 'stop',
      ),
      ShortcutItem(
        type: 'sos',
        localizedTitle: loc.sosAction,
        icon: 'exclamation',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

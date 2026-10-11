import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme_provider.dart';

/// زر تبديل النظام بين الغامق والفاتح — مستقل تماماً ومُعاد استخدامه.
class AppThemeToggleButton extends ConsumerWidget {
  const AppThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(themeModeProvider);
    final effectiveDark =
        mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Material(
      color: theme.colorScheme.primary,
      elevation: 4,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          ref
              .read(themeModeProvider.notifier)
              .setThemeMode(effectiveDark ? ThemeMode.light : ThemeMode.dark);
        },
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            effectiveDark ? Icons.wb_sunny : Icons.nightlight_round,
            color: theme.colorScheme.onPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

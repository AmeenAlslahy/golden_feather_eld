import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/press_feedback.dart';
import '../../../../routes.dart';
import '../providers/home_provider.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../core/extensions/context_extensions.dart';

/// الدرج الجانبي — مطابق للقطة Menu (بدون رأس ذهبي، بدون أسهم).
class EldDrawer extends ConsumerWidget {
  const EldDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItems = ref.watch(menuProvider);
    final loc = context.loc;
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.primaryGold,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.lg,
              ),
              child: Text(
                loc.menuTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.surface,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: menuItems.length,
                separatorBuilder: (_, __) => const Divider(
                  color: AppColors.border,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  final title = item.titleBuilder(loc);
                  return ListTile(
                    splashColor: PressFeedback.ink,
                    leading: Icon(item.icon, size: 24),
                    title: Text(
                      title,
                      style: context.styles.body,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      final currentRoute =
                          GoRouterState.of(context).matchedLocation;
                      if (item.route == currentRoute) return;
                      if (item.route == AppRoutes.home) {
                        context.go(item.route);
                      } else {
                        context.push(item.route);
                      }
                    },
                  );
                },
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            ListTile(
              splashColor: PressFeedback.ink,
              leading: const Icon(Icons.settings_outlined, size: 24),
              title: Text(
                loc.settingsTitle,
                style: context.styles.body,
              ),
              onTap: () {
                Navigator.pop(context);
                final currentRoute = GoRouterState.of(context).matchedLocation;
                if (currentRoute == AppRoutes.settings) return;
                context.push(AppRoutes.settings);
              },
            ),
            ListTile(
              splashColor: PressFeedback.ink,
              leading: const Icon(Icons.logout, size: 24, color: AppColors.dangerRed),
              title: Text(
                context.loc.logout,
                style: context.styles.error,
              ),
              onTap: () => _showLogoutDialog(context, ref),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? '1.0.0';
                  return Text(
                    'v$version',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.loc.logout),
        content: Text(context.loc.confirmLogout),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.loc.cancelButton),
          ),
          TextButton(
            onPressed: () async {
              final router = GoRouter.of(context);
              Navigator.pop(dialogContext);
              Navigator.pop(context);
              await ref.read(authStateProvider.notifier).logout();
              router.go(AppRoutes.login);
            },
            child: Text(
              context.loc.logout,
              style: context.styles.error,
            ),
          ),
        ],
      ),
    );
  }
}

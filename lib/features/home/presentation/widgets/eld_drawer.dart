import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../routes.dart';
import '../providers/home_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../core/extensions/context_extensions.dart';

/// الدرج الجانبي لقائمة ELD
class EldDrawer extends ConsumerWidget {
  const EldDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItems = ref.watch(menuProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final user = ref.watch(authStateProvider).user;
    final dashboard = ref.watch(dashboardDataProvider);

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      width: MediaQuery.of(context).size.width * 0.78,
      child: SafeArea(
        child: Column(
          children: [
            // ========== رأس القائمة ==========
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              color: AppColors.primaryBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // صورة السائق
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.surface.withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.person,
                      size: 32,
                      color: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // اسم السائق
                  Text(
                    user?.fullName ?? dashboard.driverName,
                    style: const TextStyle(
                      fontSize: AppTypography.bodySize,
                      fontWeight: AppTypography.bold,
                      color: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // رقم الشاحنة
                  Text(
                    dashboard.vehicleDisplayName,
                    style: const TextStyle(
                      fontSize: AppTypography.captionSize,
                      fontWeight: AppTypography.regular,
                      color: AppColors.surface,
                    ),
                  ),
                ],
              ),
            ),

            // ========== قائمة العناصر ==========
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                ),
                itemCount: menuItems.length,
                separatorBuilder: (_, __) => const Divider(
                  color: AppColors.border,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  final title = isArabic ? item.arabicTitle : item.title;

                  return ListTile(
                    leading: Icon(
                      item.icon,
                      
                      size: 24,
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppTypography.bodySize,
                        fontWeight: AppTypography.regular,
                        
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      
                      size: 20,
                    ),
                    onTap: () {
                      Navigator.pop(context); // إغلاق الدرج
                      final currentRoute = GoRouterState.of(context).matchedLocation;
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

            // ========== زر تسجيل الخروج ==========
            const Divider(color: AppColors.border, height: 1),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: AppColors.dangerRed,
                size: 24,
              ),
              title: Text(
                context.loc.logout,
                style: const TextStyle(
                  fontSize: AppTypography.bodySize,
                  fontWeight: AppTypography.regular,
                  color: AppColors.dangerRed,
                ),
              ),
              onTap: () {
                _showLogoutDialog(context, ref);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
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
            onPressed: () {
              Navigator.pop(dialogContext); // إغلاق الدايلوج
            },
            child: Text(context.loc.cancelButton),
          ),
          TextButton(
            onPressed: () async {
              final router = GoRouter.of(context);
              Navigator.pop(dialogContext); // إغلاق الدايلوج
              Navigator.pop(context); // إغلاق الدرج الجانبي

              await ref.read(authStateProvider.notifier).logout();
              
              router.go(AppRoutes.login);
            },
            child: Text(
              context.loc.logout,
              style: const TextStyle(color: AppColors.dangerRed),
            ),
          ),
        ],
      ),
    );
  }
}




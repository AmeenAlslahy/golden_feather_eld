import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/domain/duty_status/duty_status_code.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/connection_status_indicator.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../hos/presentation/pages/hos_page.dart';
import '../../../hos/presentation/pages/recap_page.dart';
import '../../../hos/presentation/pages/status_dashboard_page.dart';
import '../../../hos/presentation/providers/status_dashboard_providers.dart';
import '../../../hos/presentation/widgets/driving_lock_screen.dart';
import '../../../sync/presentation/widgets/sync_status_indicator.dart';
import '../../../tracking/presentation/providers/tracking_providers.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/eld_bottom_nav.dart';
import '../widgets/eld_drawer.dart';

final homeNavIndexProvider = StateProvider<int>((ref) => 0);

/// الشاشة الرئيسية لتطبيق ELD
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  List<Widget> _pagesFor(WidgetRef ref) {
    final flags = ref.watch(featureFlagsProvider);
    return [
      flags.useNewStatusDashboard
          ? const StatusDashboardPage()
          : const LegacyStatusDashboard(), // legacy wrapper below
      const RecapPage(),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardDataProvider);
    final currentNavIndex = ref.watch(homeNavIndexProvider);
    final statusDashboardState = ref.watch(statusDashboardProvider);

    final user = ref.watch(authStateProvider).user;
    final driverText = statusDashboardState.valueOrNull?.driver.displayText ??
        (dashboard.driverName != 'Unknown'
            ? '${dashboard.driverName} - ${user?.id ?? ""}'
            : null) ??
        user?.fullName ??
        '';

    final isDriving = statusDashboardState.valueOrNull?.currentDutyStatus == DutyStatusCode.driving;
     print(driverText);
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          // ========== شريط العنوان ==========
          appBar: AppBar(
            title: Text(
              currentNavIndex == 0
                  ? driverText
                  : context.loc.hoursRecap,
              style: 
              const TextStyle(
                fontSize: AppTypography.bodySize,
                fontWeight: AppTypography.bold,
                color: AppColors.surface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            centerTitle: currentNavIndex == 1, // توسيط العنوان في شاشة Recap
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: AppColors.surface),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: currentNavIndex == 0
                  ? [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      child: ConnectionStatusIndicator(),
                    ),
                    const SyncStatusIndicator(),
                    Consumer(
                      builder: (context, ref, child) {
                        final gpsStatus = ref.watch(gpsStatusProvider);
                        final isGpsOff = gpsStatus.value == ServiceStatus.disabled;
                        if (isGpsOff) {
                          return IconButton(
                            icon: const Icon(
                              Icons.build,
                              color: AppColors.warningYellow,
                              size: 28,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Problems Detected'),
                                  content: Text('• GPS is Turned Off',
                                      style: context.textTheme.bodyLarge),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ]
                : null,
          ),

          // ========== الدرج الجانبي ==========
          drawer: const EldDrawer(),

          // ========== المحتوى الرئيسي ==========
          body: Consumer(
            builder: (context, ref, child) {
              final isOnline = ref.watch(isConnectedProvider).value ?? true;
              final pages = _pagesFor(ref);
              return Column(
                children: [
                  if (!isOnline)
                    Container(
                      width: double.infinity,
                      color: AppColors.black87,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Text(
                        'Offline mode. Check your internet connection.',
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(color: AppColors.surface),
                      ),
                    ),
                  Expanded(child: pages[currentNavIndex]),
                ],
              );
            },
          ),

          // ========== شريط التنقل السفلي ==========
          bottomNavigationBar: EldBottomNav(
            currentIndex: currentNavIndex,
            onTap: (index) {
              ref.read(homeNavIndexProvider.notifier).state = index;
            },
          ),
        ),
        if (isDriving)
          const Positioned.fill(
            child: DrivingLockScreen(),
          ),
      ],
    );
  }
}

// ========== صفحات مؤقتة ==========

/// شاشة الحالة - نعرض داخلها HosPage
class LegacyStatusDashboard extends StatelessWidget {
  const LegacyStatusDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold داخل Scaffold ليس جيداً، لكن مؤقتاً لعرض محتوى HosPage
    // تم إزالة الـ AppBar من HosPage في التحديث القادم أو يتم تجاهله.
    // لتفادي تكرار الـ AppBar هنا سنقوم فقط بعرض HosPage
    return const HosPage();
  }
}

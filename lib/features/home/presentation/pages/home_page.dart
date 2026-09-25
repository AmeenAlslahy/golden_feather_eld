import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/connection_status_indicator.dart';
import '../../../../domain/duty_status/duty_status_code.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../hos/presentation/pages/change_status_page.dart';
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
    return const [
      StatusDashboardPage(),
      RecapPage(),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardDataProvider);
    final currentNavIndex = ref.watch(homeNavIndexProvider);
    final statusDashboardState = ref.watch(statusDashboardProvider);

    // الأولوية: بيانات الـ API → بيانات Auth المحلية → نص افتراضي
    final driverText = statusDashboardState.valueOrNull?.driver.displayText ??
        (dashboard.driverName != 'Unknown'
            ? '${dashboard.driverName} - ${dashboard.vehicleDisplayName}'
            : null) ??
        ref.watch(authStateProvider).user?.fullName ??
        '';

    final isDriving = statusDashboardState.valueOrNull?.currentDutyStatus == DutyStatusCode.driving;

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
              style: context.styles.appBarTitle,
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
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
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
                              final isArabic =
                                  Localizations.localeOf(context).languageCode ==
                                      'ar';
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    isArabic ? 'تنبيه' : 'Notice',
                                  ),
                                  content: Text(
                                    isArabic
                                        ? 'نظام تحديد المواقع مغلق.'
                                        : 'GPS is turned off.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(isArabic ? 'حسناً' : 'OK'),
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
                      color: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'لا يوجد إنترنت. يمكنك المتابعة وعرض البيانات المحفوظة.'
                            : 'No internet. You can continue with saved data.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  Expanded(child: pages[currentNavIndex]),
                ],
              );
            },
          ),

          // ========== شريط التنقل السفلي ==========
          bottomNavigationBar: EldBottomNav(
            showingRecap: currentNavIndex == 1,
            onRecap: () {
              ref.read(homeNavIndexProvider.notifier).state = 1;
            },
            onAvailable: () {
              if (currentNavIndex == 1) {
                ref.read(homeNavIndexProvider.notifier).state = 0;
              }
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ChangeStatusPage(),
                ),
              );
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

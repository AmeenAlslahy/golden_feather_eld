import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/duty_status/duty_status_code.dart';
import '../../../hos/presentation/pages/recap_page.dart';
import '../../../hos/presentation/widgets/driving_lock_screen.dart';
import '../../../sync/presentation/widgets/sync_status_indicator.dart';
import '../../../../core/widgets/connection_status_indicator.dart';
import '../widgets/eld_drawer.dart';
import '../widgets/eld_bottom_nav.dart';
import '../providers/dashboard_provider.dart';
import '../../../../core/network/core_providers.dart';
import '../../../tracking/presentation/providers/tracking_providers.dart';
import 'package:geolocator/geolocator.dart';
import '../../../hos/presentation/pages/status_dashboard_page.dart';
import '../../../hos/presentation/pages/change_status_page.dart';
import '../../../hos/presentation/providers/status_dashboard_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';

final homeNavIndexProvider = StateProvider<int>((ref) => 0);
final developerBypassDrivingScreenProvider = StateProvider<bool>((ref) => false);

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
        // SRS 4.2 — `Name - <driver id>`; the vehicle is not part of the header.
        (dashboard.driverName != 'Unknown'
            ? (ref.watch(currentDriverIdProvider) != null
                ? '${dashboard.driverName} - ${ref.watch(currentDriverIdProvider)}'
                : dashboard.driverName)
            : null) ??
        ref.watch(authStateProvider).user?.fullName ??
        '';

    final isDriving = statusDashboardState.valueOrNull?.currentDutyStatus == DutyStatusCode.driving;
    final developerBypass = ref.watch(developerBypassDrivingScreenProvider);

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
                    // SRS 4.2 operational alerts: server-driven tool icon +
                    // yellow triangle (`operationalAlerts`), plus the local
                    // GPS-off condition on the tool icon.
                    Consumer(
                      builder: (context, ref, child) {
                        final gpsStatus = ref.watch(gpsStatusProvider);
                        final isGpsOff = gpsStatus.value == ServiceStatus.disabled;
                        final alerts = ref
                            .watch(statusDashboardProvider)
                            .valueOrNull
                            ?.operationalAlerts;
                        final showTool = isGpsOff || (alerts?.toolIcon ?? false);
                        final showTriangle = alerts?.warningTriangleIcon ?? false;
                        if (!showTool && !showTriangle) {
                          return const SizedBox.shrink();
                        }
                        final isArabic =
                            Localizations.localeOf(context).languageCode == 'ar';
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showTool)
                              IconButton(
                                key: const Key('home_tool_alert'),
                                icon: const Icon(
                                  Icons.build,
                                  color: AppColors.warningYellow,
                                  size: 28,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                        isArabic ? 'تنبيه' : 'Notice',
                                      ),
                                      content: Text(
                                        isGpsOff
                                            ? (isArabic
                                                ? 'نظام تحديد المواقع مغلق.'
                                                : 'GPS is turned off.')
                                            : (isArabic
                                                ? 'الخادم يبلّغ عن تنبيه تشغيلي في جهاز ELD. افتح شاشة الاتصال للتفاصيل.'
                                                : 'The server reports an ELD operational alert. Open the Connection screen for details.'),
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
                              ),
                            if (showTriangle)
                              IconButton(
                                key: const Key('home_warning_triangle'),
                                tooltip: isArabic ? 'تنبيه تشغيلي' : 'Operational alert',
                                icon: const Icon(
                                  Icons.warning_amber,
                                  color: AppColors.warningYellow,
                                  size: 28,
                                ),
                                onPressed: () => context.push(AppRoutes.connection),
                              ),
                          ],
                        );
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
        if (isDriving && !developerBypass)
          const Positioned.fill(
            child: DrivingLockScreen(),
          ),
      ],
    );
  }
}

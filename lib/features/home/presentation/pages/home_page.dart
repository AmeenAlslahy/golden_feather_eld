import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/domain/entities/connection_status.dart' as core;
import '../../../../core/events/eld_events_provider.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/duty_status/duty_status_code.dart';
import '../../../../domain/duty_status/status_dashboard.dart' as dash;
import '../../../hos/presentation/pages/recap_page.dart';
import '../../../hos/presentation/widgets/driving_lock_screen.dart';
import '../../../sync/presentation/widgets/sync_status_indicator.dart';
import '../widgets/connection_status_indicator.dart';
import '../widgets/eld_drawer.dart';
import '../widgets/eld_bottom_nav.dart';
import '../providers/dashboard_provider.dart';
import '../../../../core/network/core_providers.dart';
import '../../../tracking/presentation/providers/tracking_providers.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/widgets/golden_app_bar.dart';
import '../../../hos/presentation/pages/status_dashboard_page.dart';
import '../../../hos/presentation/providers/status_dashboard_providers.dart';
import '../../../hos/presentation/providers/hos_engine_provider.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';

final homeNavIndexProvider = StateProvider<int>((ref) => 0);
final developerBypassDrivingScreenProvider = StateProvider<bool>(
  (ref) => false,
);

/// الشاشة الرئيسية لتطبيق ELD
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  List<Widget> _pagesFor(WidgetRef ref) {
    return const [StatusDashboardPage(), RecapPage()];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authGate = ref.watch(authStateProvider);
    final currentNavIndex = ref.watch(homeNavIndexProvider);
    final statusDashboardState = ref.watch(statusDashboardProvider);

    // P0 Stage 1 — بوابة محايدة: أثناء الانتقال بين الحسابات أو غياب
    // المصادقة لا تُعرض أي بيانات سائق/مركبة سابقة، ولا تُبنى الصفحات
    // الخاصة بالمستخدم. (الـ watches أعلاه تبقى غير مشروطة لاستقرار الترتيب.)
    if (!authGate.isAuthenticated || authGate.transitioning) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final driverText = ref.watch(driverSessionHeaderProvider);

    final isDriving =
        statusDashboardState.valueOrNull?.currentDutyStatus ==
        DutyStatusCode.driving;
    final isMoving = ref.watch(isVehicleMovingProvider);
    final developerBypass = ref.watch(developerBypassDrivingScreenProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          // ========== شريط العنوان ==========
          appBar: GoldenAppBar(
            variant: GoldenAppBarVariant.brand,
            title: Text(
              currentNavIndex == 0 ? driverText : context.loc.hoursRecap,
              style: context.styles.appBarTitle,
              overflow: TextOverflow.ellipsis,
            ),
            centerTitle: currentNavIndex == 1, // توسيط العنوان في شاشة Recap
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: context.onGold),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: currentNavIndex == 0
                ? [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: Consumer(
                        builder: (context, ref, child) {
                          final alerts = ref
                              .watch(statusDashboardProvider)
                              .valueOrNull
                              ?.operationalAlerts;
                          final isServerOk =
                              alerts?.connectionStatus ==
                              dash.ConnectionStatus.ok;
                          return ConnectionStatusIndicator(
                            showWarningTriangle: false,
                            statusOverride: isServerOk
                                ? core.ConnectionStatus.connected
                                : null,
                          );
                        },
                      ),
                    ),
                    const SyncStatusIndicator(),
                    // SRS 4.2 operational alerts:
                    // أيقونة الأداة مرتبطة بحالة تشغيل/إيقاف الموقع (GPS) وتختفي فور تفعيله.
                    // مثلث التحذير مرتبط بحالة اتصال جهاز ELD والأعطال التشغيلية.
                    Consumer(
                      builder: (context, ref, child) {
                        final gpsStatus = ref.watch(gpsStatusProvider);
                        final isGpsOff =
                            gpsStatus.value == ServiceStatus.disabled;
                        final alerts = ref
                            .watch(statusDashboardProvider)
                            .valueOrNull
                            ?.operationalAlerts;
                        final eldStatus =
                            ref.watch(eldConnectionStatusProvider).value;

                        final isEldDisconnected =
                            alerts?.connectionStatus ==
                                dash.ConnectionStatus.disconnected ||
                            (eldStatus != core.ConnectionStatus.connected &&
                                eldStatus != core.ConnectionStatus.connecting &&
                                alerts?.connectionStatus !=
                                    dash.ConnectionStatus.ok);

                        // تختفي أيقونة الأداة فور تفعيل الموقع وتعود أثناء إيقافه
                        final showTool = isGpsOff;
                        final showTriangle =
                            isEldDisconnected ||
                            alerts?.connectionStatus ==
                                dash.ConnectionStatus.warning ||
                            (alerts?.warningTriangleIcon ?? false);

                        if (!showTool && !showTriangle) {
                          return const SizedBox.shrink();
                        }
                        final loc = context.loc;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showTool)
                              IconButton(
                                key: const Key('home_tool_alert'),
                                icon: Icon(
                                  Icons.build,
                                  color: context.onGold,
                                  size: AppSpacing.iconLarge,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(loc.noticeTitle),
                                      content: Text(loc.gpsTurnedOff),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text(loc.okButton),
                                        ),
                                        FilledButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Geolocator.openLocationSettings();
                                          },
                                          child: Text(loc.openSettings),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            if (showTriangle)
                              IconButton(
                                key: const Key('home_warning_triangle'),
                                tooltip: loc.operationalAlertTooltip,
                                icon: Icon(
                                  Icons.warning_amber,
                                  color: context.onGold,
                                  size: AppSpacing.iconLarge,
                                ),
                                onPressed: () =>
                                    context.push(AppRoutes.connection),
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
                  if (!isOnline && currentNavIndex == 0)
                    Container(
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.inverseSurface,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        context.loc.noInternetBanner,
                        textAlign: TextAlign.center,
                        style: context.styles.subtitle.copyWith(
                          color: Theme.of(context).colorScheme.onInverseSurface,
                        ),
                      ),
                    ),
                  Expanded(
                    child: IndexedStack(
                      index: currentNavIndex,
                      children: pages,
                    ),
                  ),
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
            // صفحة تغيير الحالة تُفتح من الدائرة فقط — زر Available
            // يعيد تبويب اللوحة دون فتح أي صفحة.
            onAvailable: () {
              if (currentNavIndex == 1) {
                ref.read(homeNavIndexProvider.notifier).state = 0;
              }
            },
          ),
        ),
        if (isDriving && isMoving && !developerBypass)
          const Positioned.fill(child: DrivingLockScreen()),
      ],
    );
  }
}

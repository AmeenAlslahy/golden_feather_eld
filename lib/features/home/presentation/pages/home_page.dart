import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../hos/presentation/pages/hos_page.dart';
import '../../../hos/presentation/pages/recap_page.dart';
import '../../../sync/presentation/widgets/sync_status_indicator.dart';
import '../../../../core/widgets/connection_status_indicator.dart';
import '../widgets/eld_drawer.dart';
import '../widgets/eld_bottom_nav.dart';
import '../providers/dashboard_provider.dart';
import '../../../../core/network/core_providers.dart';
import '../../../tracking/presentation/providers/tracking_providers.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../hos/presentation/pages/status_dashboard_page.dart';

final homeNavIndexProvider = StateProvider<int>((ref) => 0);

/// الشاشة الرئيسية لتطبيق ELD
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  List<Widget> _pagesFor(WidgetRef ref) {
    final flags = ref.watch(featureFlagsProvider);
    return [
      flags.useNewStatusDashboard
          ? const StatusDashboardPage()
          : const StatusDashboard(), // legacy wrapper below
      const RecapPage(),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardDataProvider);
    final currentNavIndex = ref.watch(homeNavIndexProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // ========== شريط العنوان ==========
      appBar: AppBar(
        title: Text(
          currentNavIndex == 0
              ? '${dashboard.driverName} - ${dashboard.vehicleId}'
              : context.loc.hoursRecap,
          style: const TextStyle(
            fontSize: AppTypography.bodySize,
            fontWeight: AppTypography.bold,
            color: AppColors.surface,
          ),
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
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Problems Detected'),
                              content: const Text('• GPS is Turned Off',
                                  style: TextStyle(fontSize: 16)),
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
                  color: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: const Text(
                    'Offline mode. Check your internet connection.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 14),
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
    );
  }
}

// ========== صفحات مؤقتة ==========

/// شاشة الحالة - نعرض داخلها HosPage
class StatusDashboard extends StatelessWidget {
  const StatusDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold داخل Scaffold ليس جيداً، لكن مؤقتاً لعرض محتوى HosPage
    // تم إزالة الـ AppBar من HosPage في التحديث القادم أو يتم تجاهله.
    // لتفادي تكرار الـ AppBar هنا سنقوم فقط بعرض HosPage
    return const HosPage();
  }
}

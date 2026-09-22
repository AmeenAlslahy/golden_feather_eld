// ✅ Routes merged from main branch
import 'package:go_router/go_router.dart';

import '../features/logs/presentation/pages/switch_drivers_page.dart';
import '../features/reports/presentation/pages/reports_page.dart';
import '../features/settings/presentation/pages/developer_options_page.dart';
import '../features/settings/presentation/pages/qr_scanner_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/tracking/presentation/pages/tracking_logs_page.dart';
import '../features/tracking/presentation/pages/tracking_page.dart';
import '../routes.dart';

class MergedRoutes {
  MergedRoutes._();

  static List<RouteBase> get routes => [
        GoRoute(
          path: AppRoutes.reports,
          name: 'reports',
          builder: (context, state) => const ReportsPage(),
        ),
        GoRoute(
          path: AppRoutes.tracking,
          name: 'tracking',
          builder: (context, state) => const TrackingPage(),
        ),
        GoRoute(
          path: AppRoutes.trackingLogs,
          name: 'trackingLogs',
          builder: (context, state) => const TrackingLogsPage(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: AppRoutes.developerOptions,
          name: 'developerOptions',
          builder: (context, state) => const DeveloperOptionsPage(),
        ),
        GoRoute(
          path: AppRoutes.qrScanner,
          name: 'qrScanner',
          builder: (context, state) => const QrScannerPage(),
        ),
        GoRoute(
          path: AppRoutes.switchDrivers,
          name: 'switchDrivers',
          builder: (context, state) => const SwitchDriversPage(),
        ),
      ];
}

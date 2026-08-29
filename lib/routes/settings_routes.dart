import 'package:go_router/go_router.dart';
import '../routes.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/settings/presentation/pages/developer_options_page.dart';
import '../features/account/presentation/pages/account_page.dart';
import '../features/account/presentation/pages/rules_page.dart';
import '../features/account/presentation/pages/info_packet_page.dart';
import '../features/account/presentation/pages/user_manual_page.dart';
import '../features/reports/presentation/pages/reports_page.dart';

class SettingsRoutes {
  SettingsRoutes._();

  static List<RouteBase> get routes => [
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
          path: AppRoutes.account,
          name: 'account',
          builder: (context, state) => const AccountPage(),
        ),
        GoRoute(
          path: AppRoutes.rules,
          name: 'rules',
          builder: (context, state) => const RulesPage(),
        ),
        GoRoute(
          path: AppRoutes.infoPacket,
          name: 'info-packet',
          builder: (context, state) => const InfoPacketPage(),
        ),
        GoRoute(
          path: AppRoutes.userManual,
          name: 'userManual',
          builder: (context, state) => const UserManualPage(),
        ),
        GoRoute(
          path: AppRoutes.reports,
          name: 'reports',
          builder: (context, state) => const ReportsPage(),
        ),
      ];
}

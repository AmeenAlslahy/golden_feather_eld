import 'package:go_router/go_router.dart';
import '../routes.dart';
import '../features/account/presentation/pages/account_page.dart';
import '../features/account/presentation/pages/rules_page.dart';
import '../features/account/presentation/pages/info_packet_page.dart';
import '../features/account/presentation/pages/user_manual_page.dart';
import '../features/about/presentation/pages/about_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';

/// مسارات الحساب والوثائق وحول التطبيق (SRS §3, §6, §13, §17)
class AccountRoutes {
  AccountRoutes._();

  static List<RouteBase> get routes => [
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
          path: AppRoutes.about,
          name: 'about',
          builder: (context, state) => const AboutPage(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ];
}

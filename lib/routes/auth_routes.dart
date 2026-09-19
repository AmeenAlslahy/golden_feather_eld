import 'package:go_router/go_router.dart';
import '../routes.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/permissions/presentation/pages/permissions_page.dart';
import '../features/connection/presentation/pages/eld_connection_page.dart';
import '../features/settings/presentation/pages/server_config_page.dart';

class AuthRoutes {
  AuthRoutes._();

  static List<RouteBase> get routes => [
        GoRoute(
          path: AppRoutes.splash,
          name: 'splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: AppRoutes.permissions,
          name: 'permissions',
          builder: (context, state) => const PermissionsPage(),
        ),
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          builder: (context, state) => const AuthPage(),
        ),
        GoRoute(
          path: AppRoutes.serverConfig,
          builder: (context, state) => const ServerConfigPage(),
        ),
        GoRoute(
          path: AppRoutes.connection,
          name: 'connection',
          builder: (context, state) => const EldConnectionPage(),
        ),
      ];
}

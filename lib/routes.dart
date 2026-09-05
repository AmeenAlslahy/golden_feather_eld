import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/providers/auth_state_provider.dart';

import 'routes/auth_routes.dart';
import 'routes/home_routes.dart';
import 'routes/tracking_routes.dart';
import 'routes/logs_routes.dart';
import 'routes/dvir_routes.dart';
import 'routes/settings_routes.dart';

/// مسارات التطبيق
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String permissions = '/permissions';
  static const String connection = '/connection';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String status = '/status';
  static const String logs = '/logs';
  static const String logDetail = '/logs/:id';
  static const String editLog = '/logs/:id/edit';
  static const String tracking = '/tracking';
  static const String trackingLogs = '/tracking-logs';
  static const String dvir = '/dvir';
  static const String dvirForm = '/dvir/create';
  static const String inspection = '/inspection';
  static const String sendLogs = '/inspection/send';
  static const String codriver = '/codriver';
  static const String account = '/account';
  static const String rules = '/rules';
  static const String infoPacket = '/info-packet';
  static const String settings = '/settings';
  static const String hos = '/hos';
  static const String selectVehicle = '/select-vehicle';
  static const String userManual = '/user-manual';
  static const String developerOptions = '/developer-options';
  static const String reports = '/reports';
  static const String suggestedEvents = '/logs/suggested-events';
  static const String unidentifiedEvents = '/logs/unidentified-events';
}

/// منبه (Notifier) يربط بين Riverpod و GoRouter لتحديث المسارات
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// تكوين GoRouter
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;
      final isRegisterRoute = state.matchedLocation == AppRoutes.register;
      final isSplashRoute = state.matchedLocation == AppRoutes.splash;

      // السماح بمسار splash و permissions دائماً حتى نتحقق
      if (isSplashRoute || state.matchedLocation == AppRoutes.permissions) return null;

      // إذا لم يسجل الدخول، توجيه إلى صفحة الدخول (إلا إذا كان في صفحة التسجيل)
      if (!isLoggedIn && !isLoginRoute && !isRegisterRoute) return AppRoutes.login;

      // إذا سجل الدخول ويحاول الوصول لصفحة الدخول، توجيه لصفحة الاتصال
      if (isLoggedIn && isLoginRoute) return AppRoutes.connection;

      return null;
    },
    routes: [
      ...AuthRoutes.routes,
      ...HomeRoutes.routes,
      ...TrackingRoutes.routes,
      ...LogsRoutes.routes,
      ...DvirRoutes.routes,
      ...SettingsRoutes.routes,
    ],
  );
});


import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/providers/auth_state_provider.dart';

import 'routes/auth_routes.dart';
import 'routes/home_routes.dart';
import 'routes/logs_routes.dart';
import 'routes/dvir_routes.dart';
import 'routes/account_routes.dart';

import 'routes/app_routes.dart';
export 'routes/app_routes.dart';

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
      final location = state.matchedLocation;
      final isLoginRoute = location == AppRoutes.login;

      // المسارات العامة (splash, permissions, about) متاحة دائماً
      if (AppRoutes.publicRoutes.contains(location) && !isLoginRoute) {
        return null;
      }

      // إذا لم يسجل الدخول، توجيه إلى صفحة الدخول
      if (!isLoggedIn && !isLoginRoute) return AppRoutes.login;

      // إذا سجل الدخول ويحاول الوصول لصفحة الدخول، توجيه لصفحة الاتصال
      if (isLoggedIn && isLoginRoute) return AppRoutes.connection;

      return null;
    },
    routes: [
      ...AuthRoutes.routes,
      ...HomeRoutes.routes,
      ...LogsRoutes.routes,
      ...DvirRoutes.routes,
      ...AccountRoutes.routes,
    ],
  );
});

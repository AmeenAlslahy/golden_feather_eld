import 'package:go_router/go_router.dart';
import '../routes.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/hos/presentation/pages/status_dashboard_page.dart';
import '../features/vehicle/presentation/pages/select_vehicle_page.dart';
import '../features/codriver/presentation/pages/codriver_page.dart';

class HomeRoutes {
  HomeRoutes._();

  static List<RouteBase> get routes => [
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: AppRoutes.status,
          name: 'status',
          builder: (context, state) => const StatusDashboardPage(),
        ),
        GoRoute(
          path: AppRoutes.hos,
          name: 'hos',
          builder: (context, state) => const StatusDashboardPage(),
        ),
        GoRoute(
          path: AppRoutes.selectVehicle,
          name: 'selectVehicle',
          builder: (context, state) => const SelectVehiclePage(),
        ),
        GoRoute(
          path: AppRoutes.codriver,
          name: 'codriver',
          builder: (context, state) => const CoDriverPage(),
        ),
      ];
}

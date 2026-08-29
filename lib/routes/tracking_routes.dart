import 'package:go_router/go_router.dart';
import '../routes.dart';
import '../features/tracking/presentation/pages/tracking_page.dart';
import '../features/tracking/presentation/pages/tracking_logs_page.dart';

class TrackingRoutes {
  TrackingRoutes._();

  static List<RouteBase> get routes => [
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
      ];
}

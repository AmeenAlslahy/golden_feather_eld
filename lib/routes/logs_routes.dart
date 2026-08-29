import 'package:go_router/go_router.dart';
import '../routes.dart';
import '../features/logs/presentation/pages/logs_list_page.dart';
import '../features/logs/presentation/pages/log_detail_page.dart';
import '../features/logs/presentation/pages/edit_log_page.dart';
import '../features/logs/presentation/pages/suggested_events_page.dart';
import '../features/logs/presentation/pages/unidentified_events_page.dart';

class LogsRoutes {
  LogsRoutes._();

  static List<RouteBase> get routes => [
        GoRoute(
          path: AppRoutes.logs,
          name: 'logs',
          builder: (context, state) => const LogsListPage(),
        ),
        GoRoute(
          path: AppRoutes.suggestedEvents,
          name: 'suggestedEvents',
          builder: (context, state) => const SuggestedEventsPage(),
        ),
        GoRoute(
          path: AppRoutes.unidentifiedEvents,
          name: 'unidentifiedEvents',
          builder: (context, state) => const UnidentifiedEventsPage(),
        ),
        GoRoute(
          path: AppRoutes.logDetail,
          name: 'logDetail',
          builder: (context, state) => const LogDetailPage(),
        ),
        GoRoute(
          path: AppRoutes.editLog,
          name: 'editLog',
          builder: (context, state) {
            final event = state.extra; // تمرير الـ event كـ extra
            return EditLogPage(event: event);
          },
        ),
      ];
}

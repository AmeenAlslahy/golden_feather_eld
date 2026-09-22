import 'package:go_router/go_router.dart';

import '../core/domain/shared/value_objects.dart';
import '../features/logs/presentation/pages/audit_trail_page.dart';
import '../features/logs/presentation/pages/carrier_edits_page.dart';
import '../features/logs/presentation/pages/edit_log_page.dart';
import '../features/logs/presentation/pages/log_detail_page.dart';
import '../features/logs/presentation/pages/logs_list_page.dart';
import '../features/logs/presentation/pages/suggested_events_page.dart';
import '../features/logs/presentation/pages/unidentified_events_page.dart';
import '../routes.dart';

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
          builder: (context, state) {
            // UX-HIGH-03 fix: Extract and use route parameter
            final logId = state.pathParameters['id'];
            return LogDetailPage(logId: logId);
          },
        ),
        GoRoute(
          path: AppRoutes.editLog,
          name: 'editLog',
          builder: (context, state) {
            final event = state.extra; // تمرير الـ event كـ extra
            return EditLogPage(event: event);
          },
        ),
        GoRoute(
          path: AppRoutes.carrierEdits,
          name: 'carrierEdits',
          builder: (context, state) {
            final logIdStr = state.pathParameters['id']!;
            final logId = DailyLogId(int.parse(logIdStr));
            return CarrierEditsPage(logId: logId);
          },
        ),
        GoRoute(
          path: AppRoutes.auditTrail,
          name: 'auditTrail',
          builder: (context, state) {
            final logIdStr = state.pathParameters['id']!;
            final logId = DailyLogId(int.parse(logIdStr));
            return AuditTrailPage(logId: logId);
          },
        ),
      ];
}

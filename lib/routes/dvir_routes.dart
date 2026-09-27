import 'package:go_router/go_router.dart';
import '../routes.dart';
import '../features/dvir/presentation/pages/dvir_list_page.dart';
import '../features/dvir/presentation/pages/dvir_form_page.dart';
import '../features/inspection/presentation/pages/dot_inspection_page.dart';
import '../features/inspection/presentation/pages/send_logs_page.dart';

class DvirRoutes {
  DvirRoutes._();

  static List<RouteBase> get routes => [
        GoRoute(
          path: AppRoutes.dvir,
          name: 'dvir',
          builder: (context, state) => const DvirListPage(),
        ),
        GoRoute(
          path: AppRoutes.dvirForm,
          name: 'dvirForm',
          builder: (context, state) => const DvirFormPage(),
        ),
        GoRoute(
          path: AppRoutes.inspection,
          name: 'inspection',
          builder: (context, state) => const DotInspectionPage(),
        ),
        GoRoute(
          path: AppRoutes.sendLogs,
          name: 'sendLogs',
          builder: (context, state) => const SendLogsPage(),
        ),
      ];
}

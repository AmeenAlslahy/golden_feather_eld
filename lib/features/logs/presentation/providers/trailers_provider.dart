import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/providers/dashboard_provider.dart';
import 'form_list_provider.dart';
import 'logs_provider.dart';

/// إدارة مقطورات نموذج اليوم فوق المتحكم المشترك — القواعد ومصادر
/// القراءة/الحفظ فقط (SRS 5.5–5.13؛ كان المنطق منسوخاً مع وثائق الشحن).
class TrailersNotifier extends FormListNotifier {
  @override
  FormListRules get rules =>
      const FormListRules(maxCount: 5, labelMaxLength: 50);

  @override
  List<String> savedItems(LogsState logsState) {
    final selected = logsState.selectedLog;
    final form = logsState.serverForm;
    return form?.trailers ?? selected?.trailers ?? const [];
  }

  @override
  String? liveDashboardRaw() =>
      ref.watch(dashboardDataProvider.select((d) => d.trailerId));

  @override
  void persist(List<String> next) {
    final selected = ref.read(logsProvider).selectedLog;
    if (selected != null && !selected.today) {
      ref.read(logsProvider.notifier).updateSelectedFormLists(trailers: next);
      return;
    }
    ref.read(dashboardDataProvider.notifier).updateTrailers(next);
  }
}

/// موفر إدارة المقطورات
final trailersProvider =
    AutoDisposeNotifierProvider<TrailersNotifier, FormListState>(
      TrailersNotifier.new,
    );

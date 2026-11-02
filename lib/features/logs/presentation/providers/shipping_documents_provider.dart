import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../domain/entities/daily_form_data.dart';
import '../../domain/entities/daily_log.dart';
import 'form_list_provider.dart';
import 'logs_provider.dart';

/// إدارة وثائق شحن نموذج اليوم فوق المتحكم المشترك (SRS 5.5–5.13؛ كان
/// المنطق منسوخاً مع المقطورات).
class ShippingDocumentsNotifier extends FormListNotifier {
  @override
  FormListRules get rules => const FormListRules(
    hardMaxLength: 100,
    forbidComma: true,
    labelMaxLength: 100,
    allowSlash: true,
  );

  @override
  List<String> savedFromServerForm(DailyFormData form) =>
      form.shippingDocuments;

  @override
  List<String> savedFromLogRow(DailyLog log) => log.shippingDocuments;

  @override
  String? liveDashboardRaw() =>
      ref.watch(dashboardDataProvider.select((d) => d.shippingDocuments));

  @override
  void persist(List<String> next) {
    final selected = ref.read(logsProvider).selectedLog;
    if (selected != null && !selected.today) {
      ref
          .read(logsProvider.notifier)
          .updateSelectedFormLists(shippingDocuments: next);
      return;
    }
    ref.read(dashboardDataProvider.notifier).updateShippingDocuments(next);
  }
}

/// موفر وثائق الشحن
final shippingDocumentsProvider =
    AutoDisposeNotifierProvider<ShippingDocumentsNotifier, FormListState>(
      ShippingDocumentsNotifier.new,
    );

/// الاسم البديل للتوافق البرمجي الكامل
final shippingDocumentsControllerProvider = shippingDocumentsProvider;

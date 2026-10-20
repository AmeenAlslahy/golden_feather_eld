import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../domain/daily_form_rules.dart';
import 'logs_provider.dart';

/// أسباب فشل عمليات وثائق الشحن وفق قواعد النموذج اليومي (SRS 5.5–5.13).
enum ShippingDocumentActionFailure {
  empty,
  tooLong,
  containsComma,
  invalidFormat,
  alreadyExists,
}

/// حدث ناتج عن عملية على وثائق الشحن.
enum ShippingDocumentEvent {
  none,
  addedSuccessfully,
  failed,
}

/// حالة إدارة وثائق الشحن بالكامل.
class ShippingDocumentsState {
  final List<String> documents;
  final ShippingDocumentActionFailure? failure;
  final ShippingDocumentEvent event;

  const ShippingDocumentsState({
    required this.documents,
    this.failure,
    this.event = ShippingDocumentEvent.none,
  });

  ShippingDocumentsState copyWith({
    List<String>? documents,
    ShippingDocumentActionFailure? failure,
    bool clearFailure = false,
    ShippingDocumentEvent? event,
  }) {
    return ShippingDocumentsState(
      documents: documents ?? this.documents,
      failure: clearFailure ? null : (failure ?? this.failure),
      event: event ?? this.event,
    );
  }
}

/// متحكم وموفر إدارة وثائق الشحن المفصول تماماً عن طبقة العرض والـ BuildContext.
class ShippingDocumentsNotifier
    extends AutoDisposeNotifier<ShippingDocumentsState> {
  @override
  ShippingDocumentsState build() {
    final logsState = ref.watch(logsProvider);
    final selected = logsState.selectedLog;
    if (selected != null && !selected.today) {
      // سجل سابق: المصدر قيمه المحفوظة الخاصة به، لا حالة اللوحة الحية.
      final form = logsState.serverForm;
      return ShippingDocumentsState(
        documents: List.of(form?.shippingDocuments ?? selected.shippingDocuments),
      );
    }
    final raw =
        ref.watch(dashboardDataProvider.select((d) => d.shippingDocuments));
    return ShippingDocumentsState(documents: splitFormList(raw));
  }

  /// يحفظ القائمة الجديدة في المصدر الصحيح: الحالة الحية لسجل اليوم،
  /// أو نموذج السجل نفسه لأي سجل سابق.
  void _persist(List<String> next) {
    final selected = ref.read(logsProvider).selectedLog;
    if (selected != null && !selected.today) {
      ref
          .read(logsProvider.notifier)
          .updateSelectedFormLists(shippingDocuments: next);
      return;
    }
    ref.read(dashboardDataProvider.notifier).updateShippingDocuments(next);
  }

  /// يضيف وثيقة شحن جديدة بعد التحقق من صحتها وقواعدها وتحديث الحالة.
  void addDocument(String rawInput) {
    final text = rawInput.trim();
    if (text.isEmpty) {
      state = state.copyWith(
        failure: ShippingDocumentActionFailure.empty,
        event: ShippingDocumentEvent.failed,
      );
      return;
    }
    if (text.length > 100) {
      state = state.copyWith(
        failure: ShippingDocumentActionFailure.tooLong,
        event: ShippingDocumentEvent.failed,
      );
      return;
    }
    if (text.contains(',')) {
      state = state.copyWith(
        failure: ShippingDocumentActionFailure.containsComma,
        event: ShippingDocumentEvent.failed,
      );
      return;
    }
    if (!isFormLabelValid(text, 100, allowSlash: true)) {
      state = state.copyWith(
        failure: ShippingDocumentActionFailure.invalidFormat,
        event: ShippingDocumentEvent.failed,
      );
      return;
    }
    if (state.documents.contains(text)) {
      state = state.copyWith(
        failure: ShippingDocumentActionFailure.alreadyExists,
        event: ShippingDocumentEvent.failed,
      );
      return;
    }

    _persist([...state.documents, text]);

    state = state.copyWith(
      clearFailure: true,
      event: ShippingDocumentEvent.addedSuccessfully,
    );
  }

  /// يحذف وثيقة الشحن المحددة ويحدث الحالة المشتركة.
  void removeDocument(String doc) {
    _persist(state.documents.where((d) => d != doc).toList());
  }
}

/// موفر وثائق الشحن
final shippingDocumentsProvider = AutoDisposeNotifierProvider<
    ShippingDocumentsNotifier, ShippingDocumentsState>(
  ShippingDocumentsNotifier.new,
);

/// الاسم البديل للتوافق البرمجي الكامل
final shippingDocumentsControllerProvider = shippingDocumentsProvider;

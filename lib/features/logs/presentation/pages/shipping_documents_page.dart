import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../providers/shipping_documents_provider.dart';
import '../widgets/form_list_editor_view.dart';

/// شاشة وثائق الشحن — تستخدم الودجت العام [FormListEditorView] مع إدارة الحالة التفاعلية.
class ShippingDocumentsPage extends ConsumerStatefulWidget {
  const ShippingDocumentsPage({super.key});

  @override
  ConsumerState<ShippingDocumentsPage> createState() =>
      _ShippingDocumentsPageState();
}

class _ShippingDocumentsPageState extends ConsumerState<ShippingDocumentsPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ShippingDocumentsState>(shippingDocumentsProvider, (
      previous,
      next,
    ) {
      if (next.event == ShippingDocumentEvent.addedSuccessfully) {
        _controller.clear();
      } else if (next.event == ShippingDocumentEvent.failed) {
        switch (next.failure) {
          case ShippingDocumentActionFailure.empty:
            AppFeedback.error(context, context.loc.enterDocumentNumber);
            break;
          case ShippingDocumentActionFailure.tooLong:
            AppFeedback.error(context, context.loc.documentNumberTooLong);
            break;
          case ShippingDocumentActionFailure.containsComma:
            AppFeedback.error(context, context.loc.oneDocumentAtATime);
            break;
          case ShippingDocumentActionFailure.invalidFormat:
            AppFeedback.error(context, context.loc.shippingDocumentFormatError);
            break;
          case ShippingDocumentActionFailure.alreadyExists:
            _controller.clear();
            break;
          case null:
            break;
        }
      }
    });

    final docs = ref.watch(shippingDocumentsProvider).documents;

    return FormListEditorView(
      title: context.loc.shippingDocuments,
      emptyMessage: context.loc.noDocumentsAdded,
      itemIcon: Icons.description,
      items: docs,
      controller: _controller,
      inputFormatters: [
        // نفس مجموعة المدقق (+ `/` لأرقام BOL).
        FilteringTextInputFormatter.allow(
          RegExp(r'[\p{L}\p{N}\s\-_#/]', unicode: true),
        ),
      ],
      onAdd: () => ref
          .read(shippingDocumentsProvider.notifier)
          .addDocument(_controller.text),
      onRemove: (doc) =>
          ref.read(shippingDocumentsProvider.notifier).removeDocument(doc),
    );
  }
}

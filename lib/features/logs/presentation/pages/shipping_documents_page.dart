import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/form_list_provider.dart';
import '../../../../core/extensions/context_extensions.dart';
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

  /// خطأ التحقق يظهر أسفل الحقل مباشرة بدل تنبيه منفصل بعيد عنه.
  String? _errorText;

  void _setError(String? message) {
    if (_errorText == message) return;
    setState(() => _errorText = message);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FormListState>(shippingDocumentsProvider, (previous, next) {
      if (next.event == FormListEvent.addedSuccessfully) {
        _controller.clear();
        _setError(null);
      } else if (next.event == FormListEvent.failed) {
        switch (next.failure) {
          case FormListFailure.empty:
            _setError(context.loc.enterDocumentNumber);
            break;
          case FormListFailure.tooLong:
          // حد العدد غير مفعل لوثائق الشحن — مُجمَّع هنا لاستنفاء النوع المشترك.
          case FormListFailure.limitReached:
            _setError(context.loc.documentNumberTooLong);
            break;
          case FormListFailure.containsComma:
            _setError(context.loc.oneDocumentAtATime);
            break;
          case FormListFailure.invalidFormat:
            _setError(context.loc.shippingDocumentFormatError);
            break;
          case FormListFailure.alreadyExists:
            _controller.clear();
            _setError(null);
            break;
          case null:
            break;
        }
      }
    });

    final docs = ref.watch(shippingDocumentsProvider).items;

    return FormListEditorView(
      title: context.loc.shippingDocuments,
      emptyMessage: context.loc.noDocumentsAdded,
      itemIcon: Icons.description,
      items: docs,
      controller: _controller,
      errorText: _errorText,
      hintText: context.loc.documentNumberHint,
      onChanged: (_) => _setError(null),
      inputFormatters: [
        // نفس مجموعة المدقق (+ `/` لأرقام BOL).
        FilteringTextInputFormatter.allow(
          RegExp(r'[\p{L}\p{N}\s\-_#/]', unicode: true),
        ),
      ],
      onAdd: () => ref
          .read(shippingDocumentsProvider.notifier)
          .addItem(_controller.text),
      onRemove: (doc) =>
          ref.read(shippingDocumentsProvider.notifier).removeItem(doc),
    );
  }
}

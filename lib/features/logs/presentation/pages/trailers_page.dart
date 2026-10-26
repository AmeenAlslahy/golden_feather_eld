import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/form_list_provider.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../providers/trailers_provider.dart';
import '../widgets/form_list_editor_view.dart';

/// شاشة المقطورات — تستخدم الودجت العام [FormListEditorView] مع إدارة الحالة.
class TrailersPage extends ConsumerStatefulWidget {
  const TrailersPage({super.key});

  @override
  ConsumerState<TrailersPage> createState() => _TrailersPageState();
}

class _TrailersPageState extends ConsumerState<TrailersPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FormListState>(trailersProvider, (previous, next) {
      if (next.event == FormListEvent.addedSuccessfully) {
        _controller.clear();
      } else if (next.event == FormListEvent.failed) {
        switch (next.failure) {
          case FormListFailure.empty:
            break;
          case FormListFailure.limitReached:
            AppFeedback.error(context, context.loc.maxTrailersLimitReached);
            break;
          case FormListFailure.invalidFormat:
          // غير ممكنين بقواعد المقطورات (بلا حد طول صريح ولا رفض فاصلة)
          // — مجموعة مع الصيغة لأن EnumSwitch استنفادي على النوع المشترك.
          case FormListFailure.tooLong:
          case FormListFailure.containsComma:
            AppFeedback.error(context, context.loc.trailerNumberFormatError);
            break;
          case FormListFailure.alreadyExists:
            AppFeedback.error(context, context.loc.trailerAlreadyExists);
            _controller.clear();
            break;
          case null:
            break;
        }
      }
    });

    final trailers = ref.watch(trailersProvider).items;

    return FormListEditorView(
      title: context.loc.trailers,
      emptyMessage: context.loc.noTrailersAdded,
      itemIcon: Icons.local_shipping,
      items: trailers,
      controller: _controller,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(r'[\p{L}\p{N}\s\-_#]', unicode: true),
        ),
      ],
      onAdd: () =>
          ref.read(trailersProvider.notifier).addItem(_controller.text),
      onRemove: (trailer) =>
          ref.read(trailersProvider.notifier).removeItem(trailer),
    );
  }
}

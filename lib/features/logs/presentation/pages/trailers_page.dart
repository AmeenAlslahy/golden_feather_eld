import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    ref.listen<TrailersState>(trailersProvider, (previous, next) {
      if (next.event == TrailerEvent.addedSuccessfully) {
        _controller.clear();
      } else if (next.event == TrailerEvent.failed) {
        switch (next.failure) {
          case TrailerActionFailure.empty:
            break;
          case TrailerActionFailure.limitReached:
            AppFeedback.error(context, context.loc.maxTrailersLimitReached);
            break;
          case TrailerActionFailure.invalidFormat:
            AppFeedback.error(context, context.loc.trailerNumberFormatError);
            break;
          case TrailerActionFailure.alreadyExists:
            AppFeedback.error(context, context.loc.trailerAlreadyExists);
            _controller.clear();
            break;
          case null:
            break;
        }
      }
    });

    final trailers = ref.watch(trailersProvider).trailers;

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
          ref.read(trailersProvider.notifier).addTrailer(_controller.text),
      onRemove: (trailer) =>
          ref.read(trailersProvider.notifier).removeTrailer(trailer),
    );
  }
}

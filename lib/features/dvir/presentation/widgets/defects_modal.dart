import '../providers/dvir_provider.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/dvir_catalog.dart';
import '../extensions/dvir_catalog_extensions.dart';

/// Checkbox list of the live §396.11 catalog with an optional note per item.
class DefectCatalogDialog extends ConsumerStatefulWidget {
  const DefectCatalogDialog({
    super.key,
    required this.initial,
    this.title,
    this.customItems,
  });

  final List<DvirDefectSelection> initial;
  final String? title;
  final List<DvirCatalogItem>? customItems;

  @override
  ConsumerState<DefectCatalogDialog> createState() =>
      DefectCatalogDialogState();
}

class DefectCatalogDialogState extends ConsumerState<DefectCatalogDialog> {
  late final Map<String, DvirDefectSelection> _picked = {
    for (final d in widget.initial) d.item.code: d,
  };
  final Map<String, TextEditingController> _notes = {};

  @override
  void dispose() {
    for (final c in _notes.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _noteFor(DvirCatalogItem item) => _notes.putIfAbsent(
    item.code,
    () => TextEditingController(text: _picked[item.code]?.description ?? ''),
  );

  Widget _buildList(List<DvirCatalogItem> items, BuildContext context) {
    final loc = context.loc;
    if (items.isEmpty) {
      return Text(loc.dvirCatalogEmpty);
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final checked = _picked.containsKey(item.code);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: checked,
              title: Text(item.label(loc)),
              subtitle: item.critical
                  ? Text(
                      loc.dvirSafetyAffecting,
                      style: context.styles.error.copyWith(fontSize: 11),
                    )
                  : null,
              onChanged: (v) => setState(() {
                if (v == true) {
                  _picked[item.code] = DvirDefectSelection(
                    item: item,
                    description: _noteFor(item).text,
                  );
                } else {
                  _picked.remove(item.code);
                }
              }),
            ),
            if (checked)
              Padding(
                padding: const EdgeInsets.only(left: 40, bottom: 8),
                child: AppTextField(
                  controller: _noteFor(item),
                  style: context.styles.caption,
                  isDense: true,
                  hint: loc.dvirDescriptionOptional,
                  onChanged: (text) =>
                      _picked[item.code] = DvirDefectSelection(
                        item: item,
                        description: text,
                      ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final dialogTitle = widget.title ?? loc.dvirDefects396_11;

    Widget contentWidget;
    if (widget.customItems != null) {
      contentWidget = _buildList(widget.customItems!, context);
    } else {
      final catalog = ref.watch(dvirCatalogProvider);
      contentWidget = catalog.when(
        loading: () => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.dvirLoadDefectsFail),
            TextButton(
              onPressed: () => ref.invalidate(dvirCatalogProvider),
              child: Text(loc.retryAction),
            ),
          ],
        ),
        data: (items) => _buildList(items, context),
      );
    }

    return AlertDialog(
      title: Text(dialogTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: contentWidget,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancelAction),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _picked.values.toList()),
          child: Text(loc.okButton),
        ),
      ],
    );
  }
}


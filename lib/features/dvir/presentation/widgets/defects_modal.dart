import '../providers/dvir_provider.dart';
import '../../../../core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/dvir_catalog.dart';

/// Checkbox list of the live §396.11 catalog with an optional note per item.
class DefectCatalogDialog extends ConsumerStatefulWidget {
  const DefectCatalogDialog({required this.initial});

  final List<DvirDefectSelection> initial;

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

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    final catalog = ref.watch(dvirCatalogProvider);
    return AlertDialog(
      title: Text(loc.dvirDefects396_11),
      content: SizedBox(
        width: double.maxFinite,
        child: catalog.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.dvirLoadDefectsFail,
              ),
              TextButton(
                onPressed: () => ref.invalidate(dvirCatalogProvider),
                child: Text(loc.retryAction),
              ),
            ],
          ),
          data: (items) => items.isEmpty
              ? Text(loc.dvirCatalogEmpty)
              : ListView.builder(
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
                                  style: context.styles.error
                                      .copyWith(fontSize: 11),
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
                            child: TextField(
                              controller: _noteFor(item),
                              style: context.styles.caption,
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: loc.dvirDescriptionOptional,
                              ),
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
                ),
        ),
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

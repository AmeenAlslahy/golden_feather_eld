import '../providers/dvir_provider.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/core/error/failure.dart';

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
                  ? Text(loc.dvirSafetyAffecting, style: context.styles.error)
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
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.xxl,
                  bottom: AppSpacing.sm,
                ),
                child: AppTextField(
                  controller: _noteFor(item),
                  style: context.styles.caption,
                  isDense: true,
                  hint: loc.dvirDescriptionOptional,
                  onChanged: (text) => _picked[item.code] = DvirDefectSelection(
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
            // ⚠️ بلا شبكة: «إعادة المحاولة» وعدٌ كاذب — لا طلب سيصل.
            // والرسالة لا توحي بأن القوائم سليمة، حتى لا يسجّل المفتّش
            // تفتيشاً بغياب قائمة العيوب كاملة.
            if (e is NetworkFailure) ...[
              Text(loc.offlineMode, style: context.styles.subtitle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                loc.weakConnectionDelayedData,
                style: context.styles.subtitle,
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Text(loc.dvirLoadDefectsFail),
              TextButton(
                onPressed: () => ref.invalidate(dvirCatalogProvider),
                child: Text(loc.retryAction),
              ),
            ],
          ],
        ),
        data: (items) => _buildList(items, context),
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
      backgroundColor: context.colorScheme.surface,
      title: Row(
        children: [
          Icon(Icons.report_problem_outlined, color: context.gold, size: AppSpacing.iconMedium),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(dialogTitle, style: context.styles.cardTitle)),
        ],
      ),
      content: SizedBox(width: double.maxFinite, child: contentWidget),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            loc.cancelAction,
            style: context.styles.button.copyWith(color: context.colorScheme.onSurfaceVariant),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _picked.values.toList()),
          child: Text(
            loc.okButton,
            style: context.styles.button.copyWith(color: context.gold, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

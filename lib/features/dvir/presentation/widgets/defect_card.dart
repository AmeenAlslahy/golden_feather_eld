import '../../domain/dvir_catalog.dart';
import '../extensions/dvir_catalog_extensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';



class DefectCard extends StatelessWidget {
  final DvirDefectSelection defect;
  final bool readOnly;
  final VoidCallback onRemove;

  const DefectCard({
    super.key,
    required this.defect,
    required this.readOnly,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            defect.item.critical
                ? Icons.warning_amber_rounded
                : Icons.build_outlined,
            size: 16,
            color: defect.item.critical
                ? AppColors.dangerRed
                : context.colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              // الاسم دائماً، والوصف (إن وُجد) يلحقه — كان المنطق معكوساً
              // فيعرض شرطة وحيدة بدل العيب صاحب الملاحظة.
              (defect.description ?? '').trim().isEmpty
                  ? defect.item.label(loc)
                  : '${defect.item.label(loc)} — ${defect.description!.trim()}',
              style: context.styles.subtitle,
            ),
          ),
          if (!readOnly)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: AppColors.dangerRed),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}


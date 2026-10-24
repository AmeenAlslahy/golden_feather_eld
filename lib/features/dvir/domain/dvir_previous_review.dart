import 'dvir_catalog.dart';
import 'entities/dvir_report.dart';

/// أسطر العيوب المسجّلة على تقرير §396.13 السابق، كما تُعرض للسائق
/// التالي في حوار المراجعة: اختيارات الكتالوج (بملاحظاتها) ثم النصوص
/// الحرة للمركبة والمقطورة، وسقوط أخير إلى الملخص عندما لا شيء غيره.
///
/// `label` يُمرَّر من العرض (توطين) — القاعدة نفسها نقية هنا.
List<String> previousDvirDefectLines(
  DvirReport latest, {
  required String Function(DvirDefectSelection selection) label,
}) {
  return [
    for (final selection in latest.selectedDefects)
      label(selection) +
          ((selection.description?.trim().isNotEmpty ?? false)
              ? ' — ${selection.description!.trim()}'
              : ''),
    if ((latest.vehicleDefects ?? '').trim().isNotEmpty)
      latest.vehicleDefects!.trim(),
    if ((latest.trailerDefects ?? '').trim().isNotEmpty)
      latest.trailerDefects!.trim(),
    if (latest.selectedDefects.isEmpty &&
        (latest.vehicleDefects ?? '').trim().isEmpty &&
        (latest.trailerDefects ?? '').trim().isEmpty &&
        (latest.defectsSummary ?? '').trim().isNotEmpty)
      latest.defectsSummary!.trim(),
  ];
}

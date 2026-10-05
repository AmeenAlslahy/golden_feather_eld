import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../data/providers/dvir_repository_providers.dart';
import '../../domain/entities/dvir_defect.dart';
import '../providers/dvir_provider.dart';

/// العيوب النشطة لمركبة السائق (`GET /eld/dvir/defects/device/{uniqueId}`)
/// — قسم قراءة فقط أعلى قائمة الفحوصات؛ الفشل أو الفراغ لا يعرضان
/// شيئاً ولا يكسران القائمة.
class ActiveDefectsSection extends ConsumerWidget {
  const ActiveDefectsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defectsAsync = ref.watch(activeVehicleDefectsProvider);
    return defectsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (defects) {
        if (defects.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.loc.dvirActiveDefectsTitle,
                style: context.styles.bodyBold,
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final defect in defects)
                Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: ListTile(
                    dense: true,
                    onTap: () => _showDefectDetails(context, defect),
                    title: Text(
                      defect.itemName ?? defect.itemCode ?? '#${defect.id}',
                      style: context.styles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: defect.description == null
                        ? null
                        : Text(
                            defect.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: _severityPill(defect.severity),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _severityPill(String? severity) {
    final text = (severity ?? '').toUpperCase();
    final color = text.contains('HIGH')
        ? AppColors.dangerRed
        : text.contains('MED')
            ? AppColors.warningYellow
            : AppColors.successGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        text.isEmpty ? '-' : text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

void _showDefectDetails(BuildContext context, DvirDefect initial) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => _DefectDetailDialog(initial: initial),
  );
}

/// نافذة تفاصيل العيب (`GET /eld/dvir/defects/{id}`): تُفتح بالبيانات
/// المختارة ثم تُحدَّث من الخادم — فشل التحديث يُبقي المعروض.
class _DefectDetailDialog extends ConsumerStatefulWidget {
  const _DefectDetailDialog({required this.initial});

  final DvirDefect initial;

  @override
  ConsumerState<_DefectDetailDialog> createState() => _DefectDetailDialogState();
}

class _DefectDetailDialogState extends ConsumerState<_DefectDetailDialog> {
  late DvirDefect _defect = widget.initial;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    final result =
        await ref.read(dvirRepositoryProvider).getDefectDetails(_defect.id);
    if (!mounted) return;
    setState(() {
      _refreshing = false;
      result.fold((_) {}, (fresh) => _defect = fresh);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(loc.dvirDefectDetailsTitle)),
          if (_refreshing)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _labelPill(context, '${loc.dvirDefectSeverity}: ${_defect.severity ?? '-'}'),
                  _labelPill(context, '${loc.dvirDefectStage}: ${_defect.stage ?? '-'}'),
                ],
              ),
              if (_defect.outOfService == true) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  loc.dvirDefectOutOfService,
                  style: context.styles.error.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (_defect.description != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_defect.description!, style: context.styles.body),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(loc.dvirDefectRepairs, style: context.styles.bodyBold),
              const SizedBox(height: AppSpacing.xs),
              if (_defect.repairActions.isEmpty)
                Text(loc.dvirDefectNoRepairs, style: context.styles.muted)
              else
                for (final repair in _defect.repairActions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            repair.performedByName,
                            repair.actionPerformed,
                          ].whereType<String>().where((t) => t.isNotEmpty).join(' — '),
                          style: context.styles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (repair.repairNotes != null)
                          Text(repair.repairNotes!, style: context.styles.body),
                        if (repair.workOrderNumber != null)
                          Text(
                            'WO: ${repair.workOrderNumber}',
                            style: context.styles.muted,
                          ),
                      ],
                    ),
                  ),
              const SizedBox(height: AppSpacing.md),
              Text(loc.dvirDefectCertifications, style: context.styles.bodyBold),
              const SizedBox(height: AppSpacing.xs),
              if (_defect.certifications.isEmpty)
                Text(loc.dvirDefectNoCertifications, style: context.styles.muted)
              else
                for (final certification in _defect.certifications)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            certification.certifiedByName,
                            certification.certificationType,
                          ].whereType<String>().where((t) => t.isNotEmpty).join(' — '),
                          style: context.styles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (certification.certificationNotes != null)
                          Text(
                            certification.certificationNotes!,
                            style: context.styles.body,
                          ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }

  Widget _labelPill(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        text,
        style: context.styles.body.copyWith(fontSize: 12),
      ),
    );
  }
}

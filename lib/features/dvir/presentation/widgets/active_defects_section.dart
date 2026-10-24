import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../domain/defect_enums.dart';
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
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.loc.dvirLoadDefectsFail,
                style: context.styles.muted,
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(activeVehicleDefectsProvider),
              child: Text(context.loc.retryAction),
            ),
          ],
        ),
      ),
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
                    trailing: _severityPill(context, defect.severity),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _severityPill(BuildContext context, DefectSeverity? severity) {
    final type = switch (severity) {
      DefectSeverity.high => AppStatusBadgeType.error,
      DefectSeverity.medium => AppStatusBadgeType.warning,
      DefectSeverity.low => AppStatusBadgeType.success,
      null => AppStatusBadgeType.info,
    };
    return AppStatusBadge(label: severity?.wire ?? '-', type: type);
  }
}

void _showDefectDetails(BuildContext context, DvirDefect initial) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => _DefectDetailDialog(initial: initial),
  );
}

/// نافذة تفاصيل العيب (`GET /eld/dvir/defects/{id}`): تُفتح بالبيانات
/// المختارة ثم تُحدَّث من الخادم عبر المزوّد — فشل التحديث يُبقي المعروض.
class _DefectDetailDialog extends ConsumerWidget {
  const _DefectDetailDialog({required this.initial});

  final DvirDefect initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dvirDefectDetailsProvider(initial.id));
    final defect = async.valueOrNull ?? initial;
    final loc = context.loc;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(loc.dvirDefectDetailsTitle)),
          if (async.isLoading)
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
                  _labelPill(
                    context,
                    '${loc.dvirDefectSeverity}: ${defect.severity?.wire ?? '-'}',
                  ),
                  _labelPill(
                    context,
                    '${loc.dvirDefectStage}: ${defect.stage?.wire ?? '-'}',
                  ),
                ],
              ),
              if (defect.outOfService == true) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  loc.dvirDefectOutOfService,
                  style: context.styles.error.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (defect.description != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(defect.description!, style: context.styles.body),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(loc.dvirDefectRepairs, style: context.styles.bodyBold),
              const SizedBox(height: AppSpacing.xs),
              if (defect.repairActions.isEmpty)
                Text(loc.dvirDefectNoRepairs, style: context.styles.muted)
              else
                for (final repair in defect.repairActions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [repair.performedByName, repair.actionPerformed]
                              .whereType<String>()
                              .where((t) => t.isNotEmpty)
                              .join(' — '),
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
              Text(
                loc.dvirDefectCertifications,
                style: context.styles.bodyBold,
              ),
              const SizedBox(height: AppSpacing.xs),
              if (defect.certifications.isEmpty)
                Text(
                  loc.dvirDefectNoCertifications,
                  style: context.styles.muted,
                )
              else
                for (final certification in defect.certifications)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                                certification.certifiedByName,
                                certification.certificationType,
                              ]
                              .whereType<String>()
                              .where((t) => t.isNotEmpty)
                              .join(' — '),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(text, style: context.styles.caption),
    );
  }
}

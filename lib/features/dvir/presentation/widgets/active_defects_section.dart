import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../domain/defect_enums.dart';
import '../../domain/dvir_catalog.dart';
import '../../domain/entities/dvir_defect.dart';
import '../providers/dvir_provider.dart';

/// العيوب النشطة لمركبة السائق (`GET /eld/dvir/defects/device/{uniqueId}`)
/// — قسم قراءة فقط أعلى قائمة الفحوصات؛ الفشل أو الفراغ لا يعرضان
/// شيئاً ولا يكسران القائمة.
class ActiveDefectsSection extends ConsumerWidget {
  const ActiveDefectsSection({super.key, this.showEmptyState = false});

  final bool showEmptyState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defectsAsync = ref.watch(activeVehicleDefectsProvider);
    final catalog = ref.watch(dvirCatalogProvider).valueOrNull;

    return defectsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: EldCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: context.warning,
                size: AppSpacing.iconMedium,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.loc.dvirActiveDefectsTitle,
                      style: context.styles.bodyBold,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.loc.dvirLoadDefectsFail,
                      style: context.styles.caption.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppButton(
                label: context.loc.retryAction,
                type: EldButtonType.secondary,
                isCompact: true,
                isFullWidth: false,
                onPressed: () => ref.invalidate(activeVehicleDefectsProvider),
              ),
            ],
          ),
        ),
      ),
      data: (defects) {
        if (defects.isEmpty) {
          if (!showEmptyState) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxl),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 64,
                    color: context.success,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.loc.dvirDefectsNone,
                    style: context.styles.sectionTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.loc.dvirSatisfactory,
                    style: context.styles.caption.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.loc.dvirActiveDefectsTitle,
                style: context.styles.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final defect in defects)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _ActiveDefectCard(
                    defect: defect,
                    catalog: catalog,
                    onTap: () => _showDefectDetails(context, defect),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ActiveDefectCard extends StatelessWidget {
  const _ActiveDefectCard({
    required this.defect,
    required this.catalog,
    required this.onTap,
  });

  final DvirDefect defect;
  final List<DvirCatalogItem>? catalog;
  final VoidCallback onTap;

  String _resolveTitle(BuildContext context) {
    final loc = context.loc;
    final isArabic = loc.localeName == 'ar';
    if (isArabic && catalog != null && catalog!.isNotEmpty) {
      // 1. By itemCode
      final code = defect.itemCode?.trim();
      if (code != null && code.isNotEmpty) {
        final match = catalog!
            .where(
              (item) => item.code.trim().toUpperCase() == code.toUpperCase(),
            )
            .firstOrNull;
        if (match != null &&
            match.nameAr != null &&
            match.nameAr!.trim().isNotEmpty) {
          return match.nameAr!.trim();
        }
      }
      // 2. By itemName
      final name = defect.itemName?.trim();
      if (name != null && name.isNotEmpty) {
        final match = catalog!
            .where(
              (item) => item.name.trim().toLowerCase() == name.toLowerCase(),
            )
            .firstOrNull;
        if (match != null &&
            match.nameAr != null &&
            match.nameAr!.trim().isNotEmpty) {
          return match.nameAr!.trim();
        }
      }
    }
    // Default / English / Spanish / Uncataloged:
    if (defect.itemName != null && defect.itemName!.trim().isNotEmpty) {
      return defect.itemName!.trim();
    }
    if (defect.itemCode != null && defect.itemCode!.trim().isNotEmpty) {
      return defect.itemCode!.trim();
    }
    return '#${defect.id}';
  }

  String? _resolveDescription(String resolvedTitle) {
    final desc = defect.description?.trim();
    if (desc == null || desc.isEmpty) return null;

    final normalizedDesc = desc.toLowerCase().replaceAll(
      RegExp(r'[\s_\-]'),
      '',
    );
    final normalizedTitle = resolvedTitle.toLowerCase().replaceAll(
      RegExp(r'[\s_\-]'),
      '',
    );
    final normalizedItemName =
        defect.itemName?.trim().toLowerCase().replaceAll(
          RegExp(r'[\s_\-]'),
          '',
        ) ??
        '';
    final normalizedItemCode =
        defect.itemCode?.trim().toLowerCase().replaceAll(
          RegExp(r'[\s_\-]'),
          '',
        ) ??
        '';

    if (normalizedDesc == normalizedTitle ||
        (normalizedItemName.isNotEmpty &&
            normalizedDesc == normalizedItemName) ||
        (normalizedItemCode.isNotEmpty &&
            normalizedDesc == normalizedItemCode)) {
      return null;
    }

    return desc;
  }

  @override
  Widget build(BuildContext context) {
    final title = _resolveTitle(context);
    final description = _resolveDescription(title);

    return EldCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: context.styles.bodyBold.copyWith(
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _severityBadge(context, defect.severity),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: context.styles.caption.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (defect.outOfService == true ||
              (defect.stage != null &&
                  defect.stage != DefectLifecycleStage.open)) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (defect.outOfService == true)
                  AppStatusBadge(
                    label: context.loc.dvirDefectOutOfService,
                    type: AppStatusBadgeType.error,
                    icon: Icons.do_not_disturb_on_outlined,
                  ),
                if (defect.stage != null &&
                    defect.stage != DefectLifecycleStage.open)
                  AppStatusBadge(
                    label: defect.stage!.wire,
                    type: AppStatusBadgeType.info,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _severityBadge(BuildContext context, DefectSeverity? severity) {
    if (severity == null) {
      return const AppStatusBadge(label: '—', type: AppStatusBadgeType.neutral);
    }
    final (type, icon) = switch (severity) {
      DefectSeverity.high => (AppStatusBadgeType.error, Icons.error_outline),
      DefectSeverity.medium => (
        AppStatusBadgeType.warning,
        Icons.warning_amber_rounded,
      ),
      DefectSeverity.low => (AppStatusBadgeType.neutral, Icons.info_outline),
    };
    return AppStatusBadge(label: severity.wire, type: type, icon: icon);
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
      backgroundColor: context.colorScheme.surface,
      title: Row(
        children: [
          Icon(
            Icons.build_circle_outlined,
            color: context.gold,
            size: AppSpacing.iconMedium,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              loc.dvirDefectDetailsTitle,
              style: context.styles.cardTitle,
            ),
          ),
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
                    fontWeight: AppTypography.bold,
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
                            fontWeight: AppTypography.semiBold,
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
                            fontWeight: AppTypography.semiBold,
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

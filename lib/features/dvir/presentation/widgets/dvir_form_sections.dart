import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:signature/signature.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_signature_canvas.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../domain/dvir_vehicle.dart';
import '../../domain/entities/dvir_report.dart';
import 'dvir_form_components.dart';

/// تنبيه مراجعة فحص سابق §396.13 إن وجد
class DvirNoticeSection extends StatelessWidget {
  final bool hasExistingReport;
  final bool hasPreviousToReview;

  const DvirNoticeSection({
    super.key,
    required this.hasExistingReport,
    required this.hasPreviousToReview,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasExistingReport && hasPreviousToReview) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.xs,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(color: context.warning.withValues(alpha: 0.6)),
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: context.warning,
                size: AppSpacing.iconMedium,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.dvirPreviousReviewNotice,
                  style: context.styles.body.copyWith(
                    color: context.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// قسم اختيار نوع الفحص (Pre-Trip / Post-Trip)
class DvirInspectionTypeSection extends StatelessWidget {
  final InspectionType selectedType;
  final ValueChanged<InspectionType>? onTypeChanged;
  final bool readOnly;

  const DvirInspectionTypeSection({
    super.key,
    required this.selectedType,
    this.onTypeChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xs,
      ),
      child: DvirFieldGroup(
        title: loc.inspectionType,
        icon: Icons.fact_check_outlined,
        child: SegmentedButton<InspectionType>(
          style: ButtonStyle(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
            ),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return context.gold.withValues(alpha: 0.2);
              }
              return context.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              );
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return context.gold;
              }
              return context.colorScheme.onSurface;
            }),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return BorderSide(color: context.gold, width: 1.5);
              }
              return BorderSide(
                color: context.colorScheme.outlineVariant.withValues(
                  alpha: 0.5,
                ),
              );
            }),
          ),
          segments: [
            ButtonSegment<InspectionType>(
              value: InspectionType.preTrip,
              label: Text(
                context.translateInspectionType(InspectionType.preTrip.name),
                style: context.styles.bodyBold,
              ),
              icon: const Icon(Icons.play_circle_outline),
            ),
            ButtonSegment<InspectionType>(
              value: InspectionType.postTrip,
              label: Text(
                context.translateInspectionType(InspectionType.postTrip.name),
                style: context.styles.bodyBold,
              ),
              icon: const Icon(Icons.stop_circle_outlined),
            ),
          ],
          selected: {selectedType},
          onSelectionChanged: readOnly
              ? null
              : (newSelection) {
                  if (newSelection.isNotEmpty) {
                    onTypeChanged?.call(newSelection.first);
                  }
                },
        ),
      ),
    );
  }
}

/// قسم وقت الفحص
class DvirTimeSection extends StatelessWidget {
  final String currentTime;
  final VoidCallback? onTap;
  final bool readOnly;

  const DvirTimeSection({
    super.key,
    required this.currentTime,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xs,
      ),
      child: DvirFieldGroup(
        title: loc.dvirTimeET,
        icon: Icons.access_time_rounded,
        trailing: !readOnly
            ? InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_calendar_outlined,
                        size: 14,
                        color: context.gold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        loc.edit,
                        style: context.styles.caption.copyWith(
                          color: context.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
        child: GestureDetector(
          onTap: readOnly ? null : onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(
                color: context.colorScheme.outlineVariant.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: AppSpacing.iconSmall,
                  color: context.gold,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    currentTime,
                    style: context.styles.bodyBold.copyWith(
                      color: readOnly ? null : context.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// قسم الموقع
class DvirLocationSection extends StatelessWidget {
  final TextEditingController controller;
  final bool readOnly;

  const DvirLocationSection({
    super.key,
    required this.controller,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xs,
      ),
      child: DvirFieldGroup(
        title: loc.location,
        icon: Icons.location_on_outlined,
        child: DvirFlatTextField(
          controller: controller,
          hint: loc.location,
          readOnly: readOnly,
          prefixIcon: Icon(
            Icons.place_outlined,
            color: context.colorScheme.onSurfaceVariant,
            size: AppSpacing.iconSmall,
          ),
        ),
      ),
    );
  }
}

/// قسم قراءة العداد
class DvirOdometerSection extends StatelessWidget {
  final TextEditingController controller;
  final bool readOnly;

  const DvirOdometerSection({
    super.key,
    required this.controller,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xs,
      ),
      child: DvirFieldGroup(
        title: loc.dvirOdometerMi,
        icon: Icons.speed_outlined,
        child: DvirFlatTextField(
          controller: controller,
          hint: loc.dvirOdometerHint,
          readOnly: readOnly,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          prefixIcon: Icon(
            Icons.speed,
            color: context.colorScheme.onSurfaceVariant,
            size: AppSpacing.iconSmall,
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              'mi',
              style: context.styles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            return parseDvirOdometer(value) == null
                ? loc.invalidOdometerReading
                : null;
          },
        ),
      ),
    );
  }
}

/// قسم المركبة والعيوب الخاصة بها
class DvirVehicleSection extends StatelessWidget {
  final String vehicleId;
  final String vehicleDisplayName;
  final String defectsText;
  final bool readOnly;
  final VoidCallback? onSelectDefects;
  final VoidCallback? onSelectVehicle;

  const DvirVehicleSection({
    super.key,
    required this.vehicleId,
    required this.vehicleDisplayName,
    required this.defectsText,
    required this.readOnly,
    this.onSelectDefects,
    this.onSelectVehicle,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xs,
      ),
      child: DvirTwoColumn(
        left: FormField<String>(
          key: ValueKey(vehicleId),
          initialValue: vehicleId,
          validator: (value) {
            if (isUnassignedVehicleId(value)) {
              return loc.dvirVehicleIdMissing;
            }
            return null;
          },
          builder: (field) {
            final hasError = field.hasError;
            final errorColor = context.colorScheme.error;

            return GestureDetector(
              onTap: readOnly ? null : onSelectVehicle,
              child: DvirCell(
                title: loc.vehicle,
                borderColor: hasError ? errorColor : null,
                icon: Icons.directions_car_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vehicleDisplayName,
                            style: context.styles.bodyBold.copyWith(
                              color: hasError ? errorColor : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!readOnly)
                          Icon(
                            Icons.arrow_drop_down,
                            color: context.colorScheme.onSurfaceVariant,
                            size: AppSpacing.iconMedium,
                          ),
                      ],
                    ),
                    if (hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          field.errorText!,
                          style: context.styles.error,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        right: DvirCell(
          title: loc.defectsTitle,
          icon: Icons.report_problem_outlined,
          child: DvirDropdownField(
            text: defectsText,
            hint: loc.defectsTitle,
            onTap: onSelectDefects,
            readOnly: readOnly,
          ),
        ),
      ),
    );
  }
}

/// قسم المقطورة والعيوب الخاصة بها
class DvirTrailerSection extends StatelessWidget {
  final TextEditingController controller;
  final String defectsText;
  final bool readOnly;
  final VoidCallback? onSelectDefects;

  const DvirTrailerSection({
    super.key,
    required this.controller,
    required this.defectsText,
    required this.readOnly,
    this.onSelectDefects,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xs,
      ),
      child: DvirTwoColumn(
        left: DvirCell(
          title: loc.trailers,
          icon: Icons.rv_hookup_outlined,
          child: DvirFlatTextField(
            controller: controller,
            hint: loc.trailer,
            readOnly: readOnly,
          ),
        ),
        right: DvirCell(
          title: loc.defectsTitle,
          icon: Icons.report_problem_outlined,
          child: DvirDropdownField(
            text: defectsText,
            hint: loc.defectsTitle,
            onTap: onSelectDefects,
            readOnly: readOnly,
          ),
        ),
      ),
    );
  }
}

/// قسم اسم الشركة
class DvirCompanySection extends StatelessWidget {
  final TextEditingController controller;
  final bool readOnly;

  const DvirCompanySection({
    super.key,
    required this.controller,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xs,
      ),
      child: DvirFieldGroup(
        title: loc.company,
        icon: Icons.business_outlined,
        child: DvirFlatTextField(
          controller: controller,
          hint: loc.company,
          readOnly: readOnly,
          prefixIcon: Icon(
            Icons.domain_outlined,
            color: context.colorScheme.onSurfaceVariant,
            size: AppSpacing.iconSmall,
          ),
        ),
      ),
    );
  }
}

/// قسم الملاحظات
class DvirRemarksSection extends StatelessWidget {
  final TextEditingController controller;
  final bool readOnly;

  const DvirRemarksSection({
    super.key,
    required this.controller,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xs,
      ),
      child: DvirFieldGroup(
        title: loc.remarks,
        icon: Icons.notes_outlined,
        child: DvirFlatTextField(
          controller: controller,
          hint: loc.remarks,
          readOnly: readOnly,
          maxLines: 3,
        ),
      ),
    );
  }
}

/// قسم اختيار حالة المركبة
class DvirStatusSection extends StatelessWidget {
  final String selectedStatusLabel;
  final VoidCallback? onOpenStatusModal;
  final bool readOnly;

  const DvirStatusSection({
    super.key,
    required this.selectedStatusLabel,
    this.onOpenStatusModal,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isSatisfactory =
        selectedStatusLabel.toLowerCase().contains('satisfactory') ||
        selectedStatusLabel.contains('مرضي') ||
        selectedStatusLabel.contains('سليم');

    final statusColor = isSatisfactory ? context.success : context.danger;
    final statusIcon = isSatisfactory
        ? Icons.check_circle_outline
        : Icons.warning_amber_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xs,
      ),
      child: DvirFieldGroup(
        title: loc.status,
        icon: Icons.health_and_safety_outlined,
        child: readOnly
            ? Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(
                      statusIcon,
                      color: statusColor,
                      size: AppSpacing.iconSmall,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        selectedStatusLabel,
                        style: context.styles.bodyBold.copyWith(
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : InkWell(
                onTap: onOpenStatusModal,
                borderRadius: BorderRadius.circular(AppRadius.input),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        statusIcon,
                        color: statusColor,
                        size: AppSpacing.iconSmall,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          selectedStatusLabel,
                          style: context.styles.bodyBold.copyWith(
                            color: statusColor,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// قسم التوقيع الرقمي
class DvirSignatureSection extends StatelessWidget {
  final SignatureController controller;
  final bool readOnly;
  final String? signatureData;

  const DvirSignatureSection({
    super.key,
    required this.controller,
    this.readOnly = false,
    this.signatureData,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (readOnly) {
      final sig = signatureData?.trim();
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.xs,
        ),
        child: EldCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.draw_outlined,
                    size: AppSpacing.iconMedium,
                    color: context.gold,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(loc.dvirSign, style: context.styles.sectionTitle),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              (sig != null && sig.isNotEmpty)
                  ? _ReadOnlySignature(dataUrl: sig)
                  : Text(loc.dvirSign, style: context.styles.muted),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xs,
      ),
      child: EldCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.draw_outlined,
                  size: AppSpacing.iconMedium,
                  color: context.gold,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(loc.dvirSign, style: context.styles.sectionTitle),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              loc.dvirSignatureRequired,
              style: context.styles.caption.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSignatureFormField(
              controller: controller,
              centerClear: true,
              height: 180,
              padding: EdgeInsets.zero,
              validator: (hasSignature) {
                if (hasSignature != true) {
                  return loc.dvirSignatureRequired;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// توقيع القراءة فقط — يُفكّ base64 مرة واحدة عند تغيّر القيمة فقط
class _ReadOnlySignature extends StatefulWidget {
  final String dataUrl;

  const _ReadOnlySignature({required this.dataUrl});

  @override
  State<_ReadOnlySignature> createState() => _ReadOnlySignatureState();
}

class _ReadOnlySignatureState extends State<_ReadOnlySignature> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = _decode(widget.dataUrl);
  }

  @override
  void didUpdateWidget(covariant _ReadOnlySignature oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataUrl != widget.dataUrl) {
      _bytes = _decode(widget.dataUrl);
    }
  }

  static Uint8List? _decode(String dataUrl) {
    try {
      final base64Part = dataUrl.contains(',')
          ? dataUrl.split(',')[1]
          : dataUrl;
      return base64Decode(base64Part);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) {
      return Text(
        AppLocalizations.of(context)!.dvirImageNotAvailable,
        style: context.styles.muted,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Image.memory(bytes, height: 140, fit: BoxFit.contain),
    );
  }
}

/// زر الإرسال النهائي
class DvirSubmitButtonSection extends StatelessWidget {
  final bool isSigned;
  final bool isSubmitting;
  final bool timeAvailable;

  /// مركبة الفحص محسومة — بلاها يُعطَّل الحفظ مع سبب مرئي بدل رفض متأخر.
  final bool hasVehicle;
  final VoidCallback? onSubmit;

  const DvirSubmitButtonSection({
    super.key,
    required this.isSigned,
    required this.isSubmitting,
    required this.timeAvailable,
    required this.hasVehicle,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final enabled = timeAvailable && isSigned && hasVehicle && !isSubmitting;
    // زر معطّل بلا سبب = سائق حائر: التعطيل دائماً مع تفسير تحته.
    // (التوقيع بلا نص سبب — لوحة التوقيع فوق الزر مباشرة تشرح نفسها.)
    String? disabledReason;
    if (!enabled && !isSubmitting) {
      if (!hasVehicle) {
        disabledReason = loc.dvirVehicleIdMissing;
      } else if (!timeAvailable) {
        disabledReason = loc.dvirTimeUnavailableShort;
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: loc.dvirSign,
            type: EldButtonType.primary,
            isLoading: isSubmitting,
            onPressed: enabled ? onSubmit : null,
          ),
          if (disabledReason != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              disabledReason,
              textAlign: TextAlign.center,
              style: context.styles.caption.copyWith(
                color: context.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

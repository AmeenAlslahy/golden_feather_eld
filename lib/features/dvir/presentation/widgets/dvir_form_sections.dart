import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_signature_canvas.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/dvir_vehicle.dart';
import '../../domain/entities/dvir_report.dart';
import 'package:signature/signature.dart';

import 'dvir_form_components.dart';

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
      return Container(
        width: double.infinity,
        color: context.warning.withValues(alpha: 0.2),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(AppLocalizations.of(context)!.dvirPreviousReviewNotice),
      );
    }
    return const SizedBox.shrink();
  }
}

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
    return DvirFieldGroup(
      title: loc.inspectionType,
      child: SegmentedButton<InspectionType>(
        segments: [
          ButtonSegment<InspectionType>(
            value: InspectionType.preTrip,
            label: Text(
              context.translateInspectionType(InspectionType.preTrip.name),
            ),
            icon: const Icon(Icons.play_circle_outline),
          ),
          ButtonSegment<InspectionType>(
            value: InspectionType.postTrip,
            label: Text(
              context.translateInspectionType(InspectionType.postTrip.name),
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
    );
  }
}

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
    return DvirFieldGroup(
      title: loc.dvirTimeET,
      child: GestureDetector(
        onTap: readOnly ? null : onTap,
        child: Text(
          currentTime,
          style: context.styles.body.copyWith(
            color: readOnly ? null : context.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

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
    return DvirFieldGroup(
      title: loc.location,
      child: DvirFlatTextField(
        controller: controller,
        hint: loc.location,
        readOnly: readOnly,
      ),
    );
  }
}

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
    return DvirFieldGroup(
      title: loc.dvirOdometerMi,
      child: DvirFlatTextField(
        controller: controller,
        hint: loc.dvirOdometerHint,
        readOnly: readOnly,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        validator: (value) {
          if (value == null || value.trim().isEmpty) return null;
          // نفس قاعدة النطاق التي تُطبَّق عند الإرسال — لا منطق مزدوج.
          return parseDvirOdometer(value) == null
              ? loc.invalidOdometerReading
              : null;
        },
      ),
    );
  }
}

class DvirVehicleSection extends StatelessWidget {
  final String vehicleId;
  final String vehicleDisplayName;

  /// نص العيوب قيمة مشتقة من الاختيارات — لا متحكم هنا.
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
    return DvirTwoColumn(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicleDisplayName,
                    style: context.styles.body.copyWith(
                      color: hasError ? errorColor : null,
                    ),
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
        child: DvirDropdownField(
          text: defectsText,
          hint: loc.defectsTitle,
          onTap: onSelectDefects,
          readOnly: readOnly,
        ),
      ),
    );
  }
}

class DvirTrailerSection extends StatelessWidget {
  final TextEditingController controller;

  /// نص عيوب المقطورة قيمة مشتقة من الاختيارات — لا متحكم هنا.
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
    return DvirTwoColumn(
      left: DvirCell(
        title: loc.trailers,
        // DVIR-local field: the report may inspect a trailer that is not the
        // current daily-form trailer, and editing it here must never rewrite
        // the daily form's list.
        child: DvirFlatTextField(
          controller: controller,
          hint: loc.trailer,
          readOnly: readOnly,
        ),
      ),
      right: DvirCell(
        title: loc.defectsTitle,
        child: DvirDropdownField(
          text: defectsText,
          hint: loc.defectsTitle,
          onTap: onSelectDefects,
          readOnly: readOnly,
        ),
      ),
    );
  }
}

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
    return DvirFieldGroup(
      title: AppLocalizations.of(context)!.company,
      child: DvirFlatTextField(
        controller: controller,
        hint: AppLocalizations.of(context)!.company,
        readOnly: readOnly,
      ),
    );
  }
}

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
    return DvirFieldGroup(
      title: loc.remarks,
      child: DvirFlatTextField(
        controller: controller,
        hint: '',
        readOnly: readOnly,
      ),
    );
  }
}

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
    return DvirFieldGroup(
      title: AppLocalizations.of(context)!.status,
      child: readOnly
          ? Text(selectedStatusLabel, style: context.styles.body)
          : InkWell(
              onTap: onOpenStatusModal,
              child: SizedBox(
                width: double.infinity,
                child: Text(selectedStatusLabel, style: context.styles.body),
              ),
            ),
    );
  }
}

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
    if (readOnly) {
      final loc = AppLocalizations.of(context)!;
      final sig = signatureData?.trim();
      return DvirFieldGroup(
        title: loc.dvirSign,
        child: (sig != null && sig.isNotEmpty)
            ? _ReadOnlySignature(dataUrl: sig)
            : Text(loc.dvirSign, style: context.styles.muted),
      );
    }
    return AppSignatureFormField(
      controller: controller,
      centerClear: true,
      height: 230,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      validator: (hasSignature) {
        if (hasSignature != true) {
          return AppLocalizations.of(context)!.dvirSignatureRequired;
        }
        return null;
      },
    );
  }
}

/// توقيع القراءة فقط — يُفكّ base64 مرة واحدة عند تغيّر القيمة فقط
/// (نفس إصلاح P2 المطبق في شاشة التفاصيل)، لا في كل build.
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

class DvirSubmitButtonSection extends StatelessWidget {
  final bool isSigned;
  final bool isSubmitting;
  final bool timeAvailable;
  final VoidCallback? onSubmit;

  const DvirSubmitButtonSection({
    super.key,
    required this.isSigned,
    required this.isSubmitting,
    required this.timeAvailable,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: AppButton(
        label: AppLocalizations.of(context)!.dvirSign,
        type: EldButtonType.agree,
        isLoading: isSubmitting,
        onPressed: !timeAvailable ? null : onSubmit,
      ),
    );
  }
}

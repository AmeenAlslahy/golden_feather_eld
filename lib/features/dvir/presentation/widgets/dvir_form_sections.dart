import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_signature_canvas.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../domain/dvir_vehicle.dart';
import '../../domain/entities/dvir_report.dart';
import 'package:signature/signature.dart';

import 'dvir_form_components.dart';

class DvirNoticeSection extends StatelessWidget {
  final DashboardData dashboard;
  final bool hasExistingReport;
  final bool hasPreviousToReview;

  const DvirNoticeSection({
    super.key,
    required this.dashboard,
    required this.hasExistingReport,
    required this.hasPreviousToReview,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasExistingReport && hasPreviousToReview) {
      return Container(
        width: double.infinity,
        color: AppColors.warningYellow.withValues(alpha: 0.2),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          AppLocalizations.of(context)!.dvirPreviousReviewNotice,
        ),
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
            label: Text(context.translateInspectionType(InspectionType.preTrip.name)),
            icon: const Icon(Icons.play_circle_outline),
          ),
          ButtonSegment<InspectionType>(
            value: InspectionType.postTrip,
            label: Text(context.translateInspectionType(InspectionType.postTrip.name)),
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
        child: Text(currentTime, style: context.styles.body.copyWith(
          color: readOnly ? null : context.colorScheme.primary,
        )),
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
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        validator: (value) {
          if (value == null || value.trim().isEmpty) return null;
          final sanitized = value.trim().replaceAll(',', '');
          final parsed = double.tryParse(sanitized);
          if (parsed == null || parsed.isNaN || parsed < 0) {
            return loc.localeName == 'ar'
                ? 'قيمة العداد غير صالحة'
                : (loc.localeName == 'es'
                    ? 'Lectura de odómetro no válida'
                    : 'Invalid odometer reading');
          }
          return null;
        },
      ),
    );
  }
}

class DvirVehicleSection extends StatelessWidget {
  final DashboardData dashboard;
  final TextEditingController defectsController;
  final bool readOnly;
  final VoidCallback? onSelectDefects;
  final VoidCallback? onSelectVehicle;

  const DvirVehicleSection({
    super.key,
    required this.dashboard,
    required this.defectsController,
    required this.readOnly,
    this.onSelectDefects,
    this.onSelectVehicle,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return DvirTwoColumn(
      left: FormField<String>(
        initialValue: dashboard.vehicleId,
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
                    dashboard.vehicleDisplayName,
                    style: context.styles.body.copyWith(
                      color: hasError ? errorColor : null,
                    ),
                  ),
                  if (hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        field.errorText!,
                        style: context.styles.error.copyWith(fontSize: 12),
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
          text: defectsController.text,
          hint: loc.defectsTitle,
          onTap: onSelectDefects,
          readOnly: readOnly,
        ),
      ),
    );
  }
}

class DvirTrailerSection extends StatelessWidget {
  final DashboardData dashboard;
  final TextEditingController defectsController;
  final bool readOnly;
  final VoidCallback? onSelectDefects;
  final VoidCallback? onSelectTrailer;

  const DvirTrailerSection({
    super.key,
    required this.dashboard,
    required this.defectsController,
    required this.readOnly,
    this.onSelectDefects,
    this.onSelectTrailer,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final trailerId = dashboard.trailerId?.trim();
    final hasTrailer = trailerId != null && trailerId.isNotEmpty;
    return DvirTwoColumn(
      left: GestureDetector(
        onTap: readOnly ? null : onSelectTrailer,
        child: DvirCell(
          title: loc.trailers,
          child: Text(
            hasTrailer ? trailerId : loc.trailers,
            style: hasTrailer
                ? context.styles.body
                : context.styles.subtitle,
          ),
        ),
      ),
      right: DvirCell(
        title: loc.defectsTitle,
        child: DvirDropdownField(
          text: defectsController.text,
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
      placeholder: 'Image not\navailable.',
      placeholderStyle: const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: Color(0xFFBDBDBD),
      ),
      centerClear: true,
      height: 230,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      validator: (hasSignature) {
        if (hasSignature != true) {
          return AppLocalizations.of(context)!.dvirSignatureRequired;
        }
        return null;
      },
    );
  }
}

class _ReadOnlySignature extends StatelessWidget {
  final String dataUrl;

  const _ReadOnlySignature({required this.dataUrl});

  @override
  Widget build(BuildContext context) {
    try {
      final base64Part =
          dataUrl.contains(',') ? dataUrl.split(',')[1] : dataUrl;
      final bytes = base64Decode(base64Part);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(bytes, height: 140, fit: BoxFit.contain),
      );
    } catch (_) {
      return Text(
        AppLocalizations.of(context)!.dvirImageNotAvailable,
        style: context.styles.muted,
      );
    }
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
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF28A745),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
          ),
          onPressed: isSubmitting || !timeAvailable ? null : onSubmit,
          child: isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'SIGN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

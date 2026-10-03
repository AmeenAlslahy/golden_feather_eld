import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_signature_canvas.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../domain/dvir_vehicle.dart';
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

class DvirTimeLocationSection extends StatelessWidget {
  final String currentTime;
  final String automaticLocation;

  const DvirTimeLocationSection({
    super.key,
    required this.currentTime,
    required this.automaticLocation,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DvirFieldGroup(
          title: loc.dvirTimeET,
          child: Text(currentTime, style: context.styles.body),
        ),
        DvirFieldGroup(
          title: loc.location,
          child: Text(automaticLocation, style: context.styles.body),
        ),
      ],
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

  const DvirVehicleSection({
    super.key,
    required this.dashboard,
    required this.defectsController,
    required this.readOnly,
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
          return DvirCell(
            title: loc.vehicle,
            // تجاوز اللون فقط عند وجود خطأ — القيمة null تعني استخدام الثيم.
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
          );
        },
      ),
      right: DvirCell(
        title: loc.defectsTitle,
        child: DvirFlatTextField(
          controller: defectsController,
          hint: loc.defectsTitle,
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

  const DvirTrailerSection({
    super.key,
    required this.dashboard,
    required this.defectsController,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final trailerId = dashboard.trailerId?.trim();
    final hasTrailer = trailerId != null && trailerId.isNotEmpty;
    return DvirTwoColumn(
      left: DvirCell(
        title: loc.trailers,
        child: Text(
          hasTrailer ? trailerId : loc.trailers,
          style: hasTrailer
              ? context.styles.body
              : context.styles.subtitle,
        ),
      ),
      right: DvirCell(
        title: loc.defectsTitle,
        child: DvirFlatTextField(
          controller: defectsController,
          hint: loc.defectsTitle,
          readOnly: readOnly,
        ),
      ),
    );
  }
}

class DvirCompanySection extends StatelessWidget {
  final String companyName;

  const DvirCompanySection({
    super.key,
    required this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    return DvirFieldGroup(
      title: AppLocalizations.of(context)!.company,
      child: Text(companyName, style: context.styles.body),
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
        hint: loc.remarks,
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(selectedStatusLabel, style: context.styles.body),
                  ),
                  Icon(Icons.arrow_drop_down, color: context.colorScheme.onSurface),
                ],
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
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: AppSpacing.sm,
      ),
      child: AppButton(
        label: isSigned ? loc.dvirSigned : loc.dvirSign,
        type: EldButtonType.agree,
        isLoading: isSubmitting,
        // زر الإرسال نفسه؛ التوقيع يُفرَض عبر validator نموذج التوقيع.
        onPressed: isSubmitting || !timeAvailable ? null : onSubmit,
      ),
    );
  }
}

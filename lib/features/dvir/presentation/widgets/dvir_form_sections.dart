import 'package:flutter/material.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_signature_canvas.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
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
  final Color borderColor;
  final Color textColor;

  const DvirTimeLocationSection({
    super.key,
    required this.currentTime,
    required this.automaticLocation,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        DvirFieldGroup(
          title: loc.dvirTimeET,
          borderColor: borderColor,
          textColor: textColor,
          child: Text(
            currentTime,
            style: context.styles.body,
          ),
        ),
        DvirFieldGroup(
          title: loc.location,
          borderColor: borderColor,
          textColor: textColor,
          child: Text(
            automaticLocation,
            style: context.styles.body,
          ),
        ),
      ],
    );
  }
}

class DvirOdometerSection extends StatelessWidget {
  final TextEditingController controller;
  final bool readOnly;
  final Color borderColor;
  final Color textColor;

  const DvirOdometerSection({
    super.key,
    required this.controller,
    required this.readOnly,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return DvirFieldGroup(
      title: loc.dvirOdometerMi,
      borderColor: borderColor,
      textColor: textColor,
      child: DvirFlatTextField(
        controller: controller,
        hint: loc.dvirOdometerHint,
        readOnly: readOnly,
        keyboardType: TextInputType.number,
      ),
    );
  }
}

class DvirVehicleSection extends StatelessWidget {
  final DashboardData dashboard;
  final TextEditingController defectsController;
  final bool readOnly;
  final Color borderColor;
  final Color textColor;

  const DvirVehicleSection({
    super.key,
    required this.dashboard,
    required this.defectsController,
    required this.readOnly,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return DvirTwoColumn(
      left: FormField<String>(
        initialValue: dashboard.vehicleId,
        validator: (value) {
          if (value == null || value.trim().isEmpty || value == 'No Vehicle') {
            return loc.dvirVehicleIdMissing;
          }
          return null;
        },
        builder: (field) {
          final hasError = field.hasError;
          final errorColor = Theme.of(context).colorScheme.error;
          return DvirCell(
            title: loc.vehicle,
            borderColor: hasError ? errorColor : borderColor,
            textColor: hasError ? errorColor : textColor,
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
        borderColor: borderColor,
        textColor: textColor,
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
  final Color borderColor;
  final Color textColor;

  const DvirTrailerSection({
    super.key,
    required this.dashboard,
    required this.defectsController,
    required this.readOnly,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return DvirTwoColumn(
      left: DvirCell(
        title: loc.trailers,
        borderColor: borderColor,
        textColor: textColor,
        child: Text(
          dashboard.trailerId ?? loc.trailers,
          style: dashboard.trailerId == null
              ? context.styles.subtitle
              : context.styles.body,
        ),
      ),
      right: DvirCell(
        title: loc.defectsTitle,
        borderColor: borderColor,
        textColor: textColor,
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
  final Color borderColor;
  final Color textColor;

  const DvirCompanySection({
    super.key,
    required this.companyName,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return DvirFieldGroup(
      title: AppLocalizations.of(context)!.company,
      borderColor: borderColor,
      textColor: textColor,
      child: Text(
        companyName,
        style: context.styles.body,
      ),
    );
  }
}

class DvirRemarksSection extends StatelessWidget {
  final TextEditingController controller;
  final bool readOnly;
  final Color borderColor;
  final Color textColor;

  const DvirRemarksSection({
    super.key,
    required this.controller,
    required this.readOnly,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return DvirFieldGroup(
      title: loc.remarks,
      borderColor: borderColor,
      textColor: textColor,
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
  final VoidCallback onOpenStatusModal;
  final Color borderColor;
  final Color textColor;

  const DvirStatusSection({
    super.key,
    required this.selectedStatusLabel,
    required this.onOpenStatusModal,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return DvirFieldGroup(
      title: AppLocalizations.of(context)!.status,
      borderColor: borderColor,
      textColor: textColor,
      child: InkWell(
        onTap: onOpenStatusModal,
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedStatusLabel,
                style: context.styles.body,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: textColor),
          ],
        ),
      ),
    );
  }
}

class DvirSignatureSection extends StatelessWidget {
  final SignatureController controller;

  const DvirSignatureSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: AppSpacing.sm,
      ),
      child: AppButton(
        label: isSigned
            ? (isAr ? 'تم التوقيع' : 'SIGNED')
            : (isAr ? 'توقيع' : 'SIGN'),
        type: EldButtonType.agree,
        isLoading: isSubmitting,
        onPressed: isSubmitting || !timeAvailable || isSigned
            ? null
            : onSubmit,
      ),
    );
  }
}

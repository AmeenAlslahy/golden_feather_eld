import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_styles.dart';
import '../../domain/entities/dvir_report.dart';

extension VehicleOperationalStatusX on VehicleOperationalStatus {
  String label(AppLocalizations loc) {
    return switch (this) {
      VehicleOperationalStatus.outOfService => loc.vehicleStatusOutOfService,
      VehicleOperationalStatus.restricted => loc.vehicleStatusRestricted,
      VehicleOperationalStatus.available => loc.vehicleStatusAvailable,
    };
  }

  Color color(AppStyles styles) {
    return switch (this) {
      VehicleOperationalStatus.outOfService => styles.error.color ?? AppColors.dangerText,
      VehicleOperationalStatus.restricted => styles.warning.color ?? AppColors.warningText,
      VehicleOperationalStatus.available => styles.success.color ?? AppColors.successText,
    };
  }
}

extension DvirConditionStatusX on DvirConditionStatus {
  String label(AppLocalizations loc) {
    return switch (this) {
      DvirConditionStatus.satisfactory => loc.dvirSatisfactory,
      DvirConditionStatus.hasDefects => loc.dvirHasDefects,
      DvirConditionStatus.defectsCorrected => loc.dvirDefectsCorrected,
      DvirConditionStatus.defectsNotCorrected => loc.dvirDefectsNotCorrected,
      DvirConditionStatus.unknown => loc.localeName == 'ar'
          ? 'غير معروف'
          : (loc.localeName == 'es' ? 'Desconocido' : 'Unknown'),
    };
  }
}

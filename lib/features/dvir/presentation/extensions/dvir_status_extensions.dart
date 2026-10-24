import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/dvir_report.dart';

extension VehicleOperationalStatusX on VehicleOperationalStatus {
  String label(AppLocalizations loc) {
    return switch (this) {
      VehicleOperationalStatus.outOfService => loc.vehicleStatusOutOfService,
      VehicleOperationalStatus.restricted => loc.vehicleStatusRestricted,
      VehicleOperationalStatus.available => loc.vehicleStatusAvailable,
    };
  }

  Color color(BuildContext context) {
    return switch (this) {
      VehicleOperationalStatus.outOfService => context.danger,
      VehicleOperationalStatus.restricted => context.warning,
      VehicleOperationalStatus.available => context.success,
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
      DvirConditionStatus.unknown => loc.statusUnknown,
    };
  }

  Color color(BuildContext context) {
    return switch (this) {
      DvirConditionStatus.satisfactory ||
      DvirConditionStatus.defectsCorrected => context.success,
      DvirConditionStatus.hasDefects ||
      DvirConditionStatus.defectsNotCorrected => context.danger,
      DvirConditionStatus.unknown => context.warning,
    };
  }
}

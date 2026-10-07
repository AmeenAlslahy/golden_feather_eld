import 'package:flutter/widgets.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../domain/duty_status/duty_status_code.dart';

/// Localized display names for [DutyStatusCode].
///
/// Falls back to the short code if the l10n key is missing.
extension DutyStatusCodeL10n on DutyStatusCode {
  /// The l10n key for the full status name.
  String get l10nKey => switch (this) {
        DutyStatusCode.offDuty => 'offDuty',
        DutyStatusCode.sleeperBerth => 'sleeperBerth',
        DutyStatusCode.driving => 'drivingStatus',
        DutyStatusCode.onDutyNotDriving => 'onDuty',
        DutyStatusCode.yardMove => 'yardMoves',
        DutyStatusCode.personalConveyance => 'personalUse',
      };

  /// Resolves the display name using the current locale.
  String displayName(BuildContext context) {
    try {
      final loc = context.loc;
      return switch (this) {
        DutyStatusCode.offDuty => loc.offDuty,
        DutyStatusCode.sleeperBerth => loc.sleeperBerth,
        DutyStatusCode.driving => loc.drivingStatus,
        DutyStatusCode.onDutyNotDriving => loc.onDuty,
        DutyStatusCode.yardMove => loc.yardMoves,
        DutyStatusCode.personalConveyance => loc.personalUse,
      };
    } catch (_) {
      // Fallback if l10n key missing.
      return shortCode;
    }
  }
}

/// Localized display names for [DutyStatus] (ELD engine enum).
extension DutyStatusL10n on DutyStatus {
  String displayName(BuildContext context) {
    final loc = context.loc;
    return switch (this) {
      DutyStatus.offDuty => loc.offDuty,
      DutyStatus.sleeperBerth => loc.sleeperBerth,
      DutyStatus.driving => loc.drivingStatus,
      DutyStatus.onDutyNotDriving => loc.onDuty,
      DutyStatus.personalUse => loc.personalUse,
    };
  }
}

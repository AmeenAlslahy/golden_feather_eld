import 'package:flutter/material.dart';

import '../../../../core/design_system.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vehicle.dart';

/// صف مركبة مطابق للقطة (رقم + سنة وموديل).
///
/// SRS 9.2/9.4: the row states *before* the tap whether the driver may
/// operate it. View-only rows (company fleet not assigned to the driver, or in
/// use by another driver) are dimmed and carry a badge; tapping them still
/// shows the refusal message instead of starting a session.
class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final bool operable;
  final VoidCallback onTap;

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.operable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleBits = <String>[
      if (vehicle.year.isNotEmpty) vehicle.year,
      if (vehicle.name.isNotEmpty) vehicle.name,
    ];
    final badge = _rowBadge(context.loc);
    final reason = vehicle.statusReason?.trim() ?? '';
    return InkWell(
      onTap: onTap,
      splashColor: Colors.black.withValues(alpha: 0.12),
      highlightColor: Colors.black.withValues(alpha: 0.06),
      child: Opacity(
        opacity: operable ? 1.0 : 0.55,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.id.isNotEmpty ? vehicle.id : vehicle.displayName,
                      style: context.styles.bodyBold,
                    ),
                    if (subtitleBits.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitleBits.join(' '),
                        style: context.styles.caption,
                      ),
                    ],
                    if (!operable && reason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(reason, style: context.styles.caption),
                    ],
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: AppSpacing.sm),
                badge,
              ],
            ],
          ),
        ),
      ),
    );
  }

  AppStatusBadge? _rowBadge(AppLocalizations loc) {
    if (vehicle.inUseByOther == true) {
      return AppStatusBadge(label: loc.inUse, type: AppStatusBadgeType.error);
    }
    if (!operable) {
      return AppStatusBadge(
        label: loc.viewOnly,
        type: AppStatusBadgeType.warning,
      );
    }
    if (vehicle.isAssigned) {
      return AppStatusBadge(
        label: loc.assignedToYou,
        type: AppStatusBadgeType.success,
      );
    }
    return null;
  }
}

String vehicleErrorText(String raw, AppLocalizations loc) {
  switch (raw) {
    case 'motionUnknown':
      return loc.errMotionUnknown;
    case 'vehicleMoving':
      return loc.errVehicleMoving;
    case 'identifierMissing':
    case 'vehicle_identifier_missing':
      return loc.errIdentifierMissing;
    case 'thresholdMissing':
      return loc.errThresholdMissing;
    case 'unauthorized':
      return loc.errUnauthorized;
    case 'unavailable':
      return loc.errUnavailable;
    case 'in_use':
      return loc.errInUse;
    case 'rejected':
      return loc.errRejected;
    case 'vehicle_list_unreadable':
      return loc.errListUnreadable;
    default:
      return raw;
  }
}

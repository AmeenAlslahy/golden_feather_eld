import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_gap.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/tracking_provider.dart';

/// بطاقة حالة التتبع
class TrackingStatusCard extends ConsumerWidget {
  const TrackingStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingState = ref.watch(trackingStateProvider);
    final isTracking = trackingState.isTracking;
    final location = trackingState.currentLocation;
    final loc = AppLocalizations.of(context)!;

    return EldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: isTracking
                    ? AppColors.successGreen
                    : AppColors.textSecondary,
                size: 28,
              ),
              AppGap.hSm,
              Expanded(
                child: Text(
                  loc.trackingStatus,
                  style: AppTextStyles(context).sectionTitle,
                ),
              ),
              // مؤشر الحالة
              AppStatusBadge(
                label: isTracking ? loc.activeStatus : loc.stoppedStatus,
                type: isTracking
                    ? AppStatusBadgeType.success
                    : AppStatusBadgeType.error,
              ),
            ],
          ),
          AppGap.md,

          // الإحداثيات
          if (location != null) ...[
            _buildInfoRow(
              context,
              Icons.my_location,
              loc.coordinatesLabel,
              '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
            ),
            AppGap.sm,
          ],

          // معلومات إضافية
          _buildInfoRow(
            context,
            Icons.access_time,
            loc.lastUpdateLabel,
            location != null
                ? '${location.timestamp.hour}:${location.timestamp.minute.toString().padLeft(2, '0')}'
                : loc.noData,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        AppGap.hSm,
        Text(
          '$label: ',
          style: AppTextStyles(context).caption,
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles(context).body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

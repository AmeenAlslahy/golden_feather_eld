import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/eld_card.dart';

/// بطاقة قائمة التحقق للتأكد من جاهزية البلوتوث والـ ELD قبل الاتصال
class ConnectionChecklistCard extends StatelessWidget {
  const ConnectionChecklistCard({super.key});

  @override
  Widget build(BuildContext context) {
    return EldCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.checklist_rtl_rounded,
                  color: context.gold,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.loc.verifyFollowingItems,
                  key: const Key('connection_checklist_title'),
                  style: context.styles.cardTitle.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.compact),
          _buildChecklistItem(context, context.loc.macEnteredCorrectly),
          _buildChecklistItem(context, context.loc.hardwareProperlyInstalled),
          _buildChecklistItem(context, context.loc.vehiclePowerOn),
          _buildChecklistItem(context, context.loc.bluetoothEnabled),
          _buildChecklistItem(context, context.loc.gpsEnabled),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.compact),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsetsDirectional.only(
              top: 7,
              end: AppSpacing.sm + 2,
            ),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: context.gold,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(child: Text(text, style: context.styles.body)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_gap.dart';
import '../providers/tracking_provider.dart';

/// إجراءات سريعة - من quick_actions.dart الأصلي
class QuickActions extends ConsumerWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingState = ref.watch(trackingStateProvider);
    final isLoading = trackingState.status == TrackingStatus.loading;

    ref.listen<TrackingState>(trackingStateProvider, (previous, next) {
      if (next.errorType == TrackingErrorType.permission &&
          (previous?.errorType != TrackingErrorType.permission)) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.location_off,
                color: AppColors.dangerRed, size: 48),
            title: Text(context.loc.locationDisabled),
            content: Text(next.arabicErrorMessage ?? next.errorMessage ?? ''),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.loc.cancelButton),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Geolocator.openLocationSettings();
                },
                child: Text(context.loc.openSettings),
              ),
            ],
          ),
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // زر بدء/إيقاف التتبع
        AppButton(
          label: trackingState.isTracking
              ? context.loc.stopAction
              : context.loc.startAction,
          icon:
              trackingState.isTracking ? Icons.stop_circle : Icons.play_circle,
          type: trackingState.isTracking
              ? EldButtonType.danger
              : EldButtonType.connect,
          isLoading: isLoading,
          onPressed: () {
            final notifier = ref.read(trackingStateProvider.notifier);
            if (trackingState.isTracking) {
              notifier.stopTracking();
            } else {
              notifier.startTracking();
            }
          },
        ),
        AppGap.sm,

        // صف الأزرار الإضافية
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: context.loc.refreshButton,
                icon: Icons.my_location,
                type: EldButtonType.continueDisconnected,
                onPressed: () {
                  ref.read(trackingStateProvider.notifier).requestPosition();
                },
              ),
            ),
            AppGap.hSm,
            Expanded(
              child: AppButton(
                label: context.loc.sosAction,
                icon: Icons.warning_amber,
                type: EldButtonType.danger,
                onPressed: () {
                  ref
                      .read(trackingStateProvider.notifier)
                      .requestPosition(alarm: 'sos');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

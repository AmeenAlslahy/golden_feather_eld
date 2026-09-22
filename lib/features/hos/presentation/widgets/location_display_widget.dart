import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_gap.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';

class LocationDisplayWidget extends ConsumerWidget {
  const LocationDisplayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final loc = context.loc;

    final trackingState = ref.watch(trackingStateProvider);
    final locString = trackingState.currentLocation != null
        ? '${trackingState.currentLocation!.latitude.toStringAsFixed(4)}, ${trackingState.currentLocation!.longitude.toStringAsFixed(4)}'
        : loc.calculatingLocation;

    return Row(
      children: [
        Icon(Icons.location_on, color: theme.colorScheme.primary, size: 20),
        AppGap.hSm,
        Expanded(
          child: Text(
            locString,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

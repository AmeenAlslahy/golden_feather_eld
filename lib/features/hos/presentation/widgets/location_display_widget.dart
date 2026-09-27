import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';

class LocationDisplayWidget extends ConsumerWidget {
  const LocationDisplayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final loc = context.loc;

    // select على النص المعروض فقط حتى لا تعاد بناء الويدجت كل نبضة GPS.
    final coords = ref.watch(trackingStateProvider.select((s) {
      final l = s.currentLocation;
      return l == null
          ? null
          : '${l.latitude.toStringAsFixed(4)}, ${l.longitude.toStringAsFixed(4)}';
    }));
    final locString = coords ?? loc.calculatingLocation;

    return Row(
      children: [
        Icon(Icons.location_on, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: AppSpacing.sm),
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

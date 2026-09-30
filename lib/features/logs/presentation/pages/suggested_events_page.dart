import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../routes.dart';

/// Live OpenAPI has unidentified events, not a separate suggested-events API.
class SuggestedEventsPage extends ConsumerWidget {
  const SuggestedEventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.loc.suggestedEvents,
          style: context.styles.appBarTitle,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.surface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SRS 6.6 / §395.30: carrier-proposed edits are reviewed per log
            // (Certify tab); unidentified driving is reviewed in Unidentified
            // Events. This screen only routes the driver to the right place.
            Text(
              context.loc.carrierProposedEdits39530Are,
              key: const Key('suggested_events_carrier_hint'),
              textAlign: TextAlign.center,
              style: context.styles.body,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.loc.unidentifiedDrivingIsReviewedInUnidentified,
              textAlign: TextAlign.center,
              style: context.styles.body,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: context.loc.logsTitle,
              type: EldButtonType.dark,
              onPressed: () => context.go(AppRoutes.logs),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: context.loc.unidentifiedEvents,
              type: EldButtonType.dark,
              onPressed: () => context.push(AppRoutes.unidentifiedEvents),
            ),
          ],
        ),
      ),
    );
  }
}

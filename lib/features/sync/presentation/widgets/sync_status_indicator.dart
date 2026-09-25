import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../sync/presentation/providers/sync_provider.dart';

/// مؤشر حالة المزامنة
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);

    if (syncState.totalPending == 0 && !syncState.isSyncing) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () {
        ref.read(syncStateProvider.notifier).syncNow();
      },
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: AppStatusBadge(
          label: syncState.isSyncing
              ? context.loc.syncing
              : context.loc.syncPending(syncState.totalPending.toString()),
          type: syncState.isSyncing
              ? AppStatusBadgeType.info
              : AppStatusBadgeType.warning,
          icon: syncState.isSyncing ? Icons.sync : Icons.sync_problem,
          trailing: syncState.totalFailed > 0
              ? Text(
                  '(${context.loc.syncFailed(syncState.totalFailed.toString())})',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.dangerRed,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

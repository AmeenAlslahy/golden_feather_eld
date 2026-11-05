import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/golden_app_bar.dart';

import '../providers/audit_trail_provider.dart';

class AuditTrailPage extends ConsumerWidget {
  const AuditTrailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trail = ref.watch(auditTrailProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GoldenAppBar(
        title: Text(context.loc.auditTrail, style: context.styles.appBarTitle),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // النص التأكيدي: كل الإجراءات محفوظة ولا يمكن تعديلها أو حذفها.
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              context.loc.auditTrailNote,
              textAlign: TextAlign.center,
              style: context.styles.body.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          Expanded(
            child: trail.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  Center(child: Text(context.loc.auditLoadFailed)),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(child: Text(context.loc.auditNoRecords));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    final subtitleParts = [
                      if (e.entityType != null && e.entityType!.isNotEmpty)
                        '${e.entityType}${e.entityId != null && e.entityId!.isNotEmpty ? ' #${e.entityId}' : ''}',
                      if (e.userName != null && e.userName!.isNotEmpty)
                        '${e.userName}${e.userRole != null && e.userRole!.isNotEmpty ? ' (${e.userRole})' : ''}',
                    ];

                    return ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.history,
                        color: context.styles.subtitle.color,
                        size: AppSpacing.iconMedium,
                      ),
                      title: Text(
                        e.action.isNotEmpty
                            ? e.action
                            : (e.newStatus.isNotEmpty
                                  ? e.newStatus
                                  : context.loc.unknownAction),
                        style: context.styles.body,
                      ),
                      subtitle: subtitleParts.isEmpty
                          ? null
                          : Text(
                              subtitleParts.join(' · '),
                              style: context.styles.caption,
                            ),
                      trailing: Text(
                        DateFormat(
                          'yyyy-MM-dd\nHH:mm',
                        ).format(e.timestamp.toLocal()),
                        textAlign: TextAlign.end,
                        style: context.styles.caption,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

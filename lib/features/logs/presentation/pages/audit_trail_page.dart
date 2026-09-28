import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/providers/log_repository_providers.dart';
import '../../domain/entities/audit_entry.dart';

/// SRS 7.16 — سجل التدقيق: أحدث 100 حدث، عرض فقط (لا تعديل ولا حذف).
final auditTrailProvider = FutureProvider<List<AuditEntry>>((ref) async {
  final repo = ref.watch(logRepositoryProvider);
  final result = await repo.getRecentAuditEntries(limit: 100);
  return result.fold((failure) => throw failure, (entries) => entries);
});

class AuditTrailPage extends ConsumerWidget {
  const AuditTrailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final trail = ref.watch(auditTrailProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.loc.auditTrail,
          style: context.styles.appBarTitle,
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // النص التأكيدي: كل الإجراءات محفوظة ولا يمكن تعديلها أو حذفها.
          Container(
            width: double.infinity,
            color: AppColors.successGreen.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              isArabic
                  ? 'يؤكد هذا السجل حفظ كل إجراء مع المستخدم والوقت والقيم السابقة والجديدة. لا يمكن تعديل هذا السجل أو حذفه.'
                  : 'This log confirms every action is kept with the user, time, and previous/new values. It cannot be edited or deleted.',
              textAlign: TextAlign.center,
              style: context.styles.muted,
            ),
          ),
          Expanded(
            child: trail.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(
                  isArabic ? 'تعذر تحميل سجل التدقيق.' : 'Could not load the audit trail.',
                ),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Text(isArabic ? 'لا توجد سجلات' : 'No Records'),
                  );
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
                      leading:  Icon(Icons.history,
                          color: AppColors.textSecondaryFor(Theme.of(context).brightness), size: 20),
                      title: Text(
                        e.action.isNotEmpty ? e.action : e.newStatus,
                        style: context.styles.body,
                      ),
                      subtitle: subtitleParts.isEmpty
                          ? null
                          : Text(
                              subtitleParts.join(' · '),
                              style: context.styles.caption,
                            ),
                      trailing: Text(
                        DateFormat('yyyy-MM-dd\nHH:mm').format(e.timestamp.toLocal()),
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

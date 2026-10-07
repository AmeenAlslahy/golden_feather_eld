import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/log_repository_providers.dart';
import '../../domain/entities/audit_entry.dart';

/// SRS 7.16 — سجل التدقيق: أحدث 100 حدث، عرض فقط (لا تعديل ولا حذف).
final auditTrailProvider = FutureProvider.autoDispose<List<AuditEntry>>((ref) async {
  final repo = ref.watch(logRepositoryProvider);
  final result = await repo.getRecentAuditEntries(limit: 100);
  return result.fold((failure) => throw failure, (entries) => entries);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/repositories/hos_audit_repository.dart';
import '../repositories/hos_audit_repository_impl.dart';
import '../../../../core/services/hos_audit_migration.dart';

/// صندوق مخالفات HOS يُفتح عند أول طلب (lazy) — وليس أثناء الإقلاع.
///
/// الترحيل من `audit_box` القديم يتم داخل نفس الـ Future مرة واحدة.
final hosAuditBoxProvider = FutureProvider<Box<String>>((ref) {
  // ⚠️ صندوق منفصل عن audit_box (سجلات السجلات اليومية).
  // كان الاثنان يتشاركان الصندوق فتفشل قراءة المخالفات كل مرة.
  // الترحيل: HosAuditBoxMigration — lib/core/services/hos_audit_migration.dart
  return openHosAuditBoxAndMigrate();
});

final hosAuditRepositoryProvider = FutureProvider<HosAuditRepository>((
  ref,
) async {
  final box = await ref.watch(hosAuditBoxProvider.future);
  return HosAuditRepositoryImpl(box);
});

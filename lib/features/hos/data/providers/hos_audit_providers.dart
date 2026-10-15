import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:golden_feather_eld/core/constants/storage_constants.dart';
import '../../domain/repositories/hos_audit_repository.dart';
import '../repositories/hos_audit_repository_impl.dart';

final hosAuditBoxProvider = Provider<Box<String>>((ref) {
  // ⚠️ صندوق منفصل عن audit_box (سجلات السجلات اليومية).
  // كان الاثنان يتشاركان الصندوق فتفشل قراءة المخالفات كل مرة.
  // الترحيل: HosAuditBoxMigration — lib/core/services/hos_audit_migration.dart
  return Hive.box<String>(StorageConstants.hosAuditBox);
});

final hosAuditRepositoryProvider = Provider<HosAuditRepository>((ref) {
  final box = ref.watch(hosAuditBoxProvider);
  return HosAuditRepositoryImpl(box);
});

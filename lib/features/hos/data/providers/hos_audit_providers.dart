import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:golden_feather_eld/core/constants/storage_constants.dart';
import '../../domain/repositories/hos_audit_repository.dart';
import '../repositories/hos_audit_repository_impl.dart';

final hosAuditBoxProvider = Provider<Box<String>>((ref) {
  return Hive.box<String>(StorageConstants.auditBox);
});

final hosAuditRepositoryProvider = Provider<HosAuditRepository>((ref) {
  final box = ref.watch(hosAuditBoxProvider);
  return HosAuditRepositoryImpl(box);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/network/core_providers.dart';
import '../../domain/repositories/inspection_repository.dart';
import '../repositories/inspection_repository_impl.dart';

/// طبقة البيانات تركّب مستودعها (المرحلة 3b) — الشبكة جزء من التركيب.
final inspectionRepositoryProvider = Provider<InspectionRepository>((ref) {
  return InspectionRepositoryImpl(
    ref.watch(inspectionBackendProvider),
    ref.watch(networkInfoProvider),
  );
});

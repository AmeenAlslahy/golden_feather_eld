import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../domain/repositories/inspection_repository.dart';
import '../repositories/inspection_repository_impl.dart';

final inspectionRepositoryProvider = Provider<InspectionRepository>((ref) {
  return InspectionRepositoryImpl(
    ref.watch(inspectionBackendProvider),
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/core_providers.dart';
import '../../domain/repositories/reports_repository.dart';
import '../repositories/reports_repository_impl.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportsRepositoryImpl(apiClient);
});

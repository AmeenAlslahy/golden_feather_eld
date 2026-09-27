import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/network/core_providers.dart';
import '../../domain/repositories/status_dashboard_repository.dart';
import '../repositories/status_dashboard_repository_impl.dart';

// --- DI: طبقة البيانات هي من تركّب مستودعها (المرحلة 3b) ---

final statusDashboardRepositoryProvider = Provider<StatusDashboardRepository>((ref) {
  return StatusDashboardRepositoryImpl(
    ref.watch(statusDashboardBackendProvider),
    ref.watch(networkInfoProvider),
  );
});

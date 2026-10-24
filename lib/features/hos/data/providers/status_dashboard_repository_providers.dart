import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/time/trusted_time_provider.dart';
import '../../domain/repositories/status_dashboard_repository.dart';
import '../datasources/dashboard_local_cache.dart';
import '../repositories/status_dashboard_repository_impl.dart';

// --- DI: طبقة البيانات هي من تركّب مستودعها (المرحلة 3b) ---

/// تخزين اللوحة والملخص على القرص — يجعل "العمل أوفلاين" ممكناً
/// عبر إعادة التشغيل بدل الاعتماد على الذاكرة فقط.
final dashboardLocalCacheProvider = Provider<DashboardLocalCache>((ref) {
  return PrefsDashboardLocalCache(ref.watch(localStorageProvider));
});

/// الساعة الموثوقة بصيغة `DateTime` للطبقة غير-التدفقية.
///
/// مسحوبة كدالة لا كقيمة: `ref.watch(trustedTimeProvider)` يُقيَّم مرة
/// واحدة عند البناء، فيُجمَّد الختم على لحظة إنشاء المستودع — وهذا بالضبط
/// العطل (كل اللقطات لاحقاً تُوسم بالوقت نفسه).
DateTime _trustedNowUtc(Ref ref) {
  final trusted = ref.read(trustedTimeProvider).currentTime;
  if (trusted is TrustedTimeAvailable) return trusted.utc.toUtc();
  // ⚠️ بلا مرساة موثوقة: ساعة الجهازالمحصورة — بديل متحفّظ فقط. لا يوجد
  // خيار أفضل هنا، والتوثيق يصرّ بأن الختم بساعة الجهاز قابل للعبث.
  return DateTime.now().toUtc();
}

final statusDashboardRepositoryProvider = Provider<StatusDashboardRepository>((
  ref,
) {
  return StatusDashboardRepositoryImpl(
    ref.watch(statusDashboardBackendProvider),
    ref.watch(networkInfoProvider),
    disk: ref.watch(dashboardLocalCacheProvider),
    trustedNowUtc: () => _trustedNowUtc(ref),
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

// جسر توافق (المرحلة 3b): تركيبة مستودع/خدمة/مصادر التتبع انتقلت إلى
// طبقة البيانات؛ هذا الملف يبقى يصدّرها للمسارات القديمة (اختبارات
// وصفحات تستورد من هنا) حتى يتم توجيه الجميع مباشرة.
export '../../data/providers/tracking_providers.dart';

/// مزود حالة خدمة الـ GPS
final gpsStatusProvider =
    StreamProvider.autoDispose<ServiceStatus>((ref) async* {
  bool isEnabled = await Geolocator.isLocationServiceEnabled();
  yield isEnabled ? ServiceStatus.enabled : ServiceStatus.disabled;
  yield* Geolocator.getServiceStatusStream();
});

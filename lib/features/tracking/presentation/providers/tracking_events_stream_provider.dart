import 'package:golden_feather_eld/core/engine/hos_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/live_tracking_data_source.dart';

/// مزود يقرأ التدفق الحي للأحداث (EldEvent) المستخرجة من نظام التتبع
/// ويقوم بإعادة بثها إلى واجهة المستخدم (مثل الرسم البياني للسجلات LogGraph).
final trackingEventsStreamProvider =
    StreamProvider.autoDispose<EldEvent>((ref) {
  final liveTracking = ref.watch(liveTrackingDataSourceProvider);
  return liveTracking.events;
});

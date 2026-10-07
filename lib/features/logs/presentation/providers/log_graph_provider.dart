import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/features/tracking/data/datasources/live_tracking_data_source.dart'; // ignore_architecture

final logGraphEventsProvider = StreamProvider.autoDispose<EldEvent>((ref) {
  return ref.watch(liveTrackingDataSourceProvider).events;
});

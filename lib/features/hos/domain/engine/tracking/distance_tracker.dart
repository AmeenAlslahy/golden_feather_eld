import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/live_tracking_data_source.dart';
import '../../../../../core/utils/distance_calculator.dart';
import '../../../../../core/time/trusted_time_provider.dart';

import '../../../../../core/domain/entities/location_point.dart';

/// متتبع المسافات
class DistanceTracker {
  final TrustedTimeProvider _timeProvider;
  final List<LocationPoint> _points = [];
  double _totalDistanceKm = 0;
  LocationPoint? _lastPoint;

  DistanceTracker(this._timeProvider);

  double get totalDistanceKm => _totalDistanceKm;
  List<LocationPoint> get points => List.unmodifiable(_points);

  /// إضافة نقطة موقع جديدة
  void addPoint(LocationPoint point) {
    _points.add(point);

    if (_lastPoint != null) {
      final distance = DistanceCalculator.haversine(
        lat1: _lastPoint!.latitude,
        lon1: _lastPoint!.longitude,
        lat2: point.latitude,
        lon2: point.longitude,
      );
      _totalDistanceKm += distance;
    }

    _lastPoint = point;
  }

  /// مسح البيانات
  void clear() {
    _points.clear();
    _totalDistanceKm = 0;
    _lastPoint = null;
  }

  /// الحصول على مسافة اليوم
  double getTodayDistance() {
    final timeResult = _timeProvider.currentTime;
    final now = timeResult is TrustedTimeAvailable
        ? timeResult.utc
        : DateTime.now().toUtc();
    final todayStart = DateTime(now.year, now.month, now.day);

    double distance = 0;
    for (int i = 1; i < _points.length; i++) {
      if (_points[i].timestamp.isAfter(todayStart)) {
        distance += DistanceCalculator.haversine(
          lat1: _points[i - 1].latitude,
          lon1: _points[i - 1].longitude,
          lat2: _points[i].latitude,
          lon2: _points[i].longitude,
        );
      }
    }
    return distance;
  }
}

/// مزود متتبع المسافات
final distanceTrackerProvider = Provider<DistanceTracker>((ref) {
  final timeProvider = ref.watch(trustedTimeProvider);
  final tracker = DistanceTracker(timeProvider);
  final dataSource = ref.watch(liveTrackingDataSourceProvider);

  final subscription = dataSource.locations.listen((point) {
    tracker.addPoint(point);
  });

  ref.onDispose(() {
    subscription.cancel();
    tracker.clear();
  });

  return tracker;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/live_tracking_data_source.dart';
import '../../../../../core/utils/distance_calculator.dart';

/// نقطة موقع
class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}

/// متتبع المسافات
class DistanceTracker {
  final List<LocationPoint> _points = [];
  double _totalDistanceKm = 0;
  LocationPoint? _lastPoint;

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
    final now = DateTime.now();
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
  final tracker = DistanceTracker();
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

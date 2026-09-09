import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/utils/distance_calculator.dart';

void main() {
  group('Haversine Distance Tests', () {
    test('calculateDistance should return correct distance', () {
      // Riyadh coordinates
      const riyadhLat = 24.7136;
      const riyadhLon = 46.6753;
      // Dammam coordinates
      const dammamLat = 26.4207;
      const dammamLon = 50.0888;

      final distance = DistanceCalculator.haversine(
        lat1: riyadhLat,
        lon1: riyadhLon,
        lat2: dammamLat,
        lon2: dammamLon,
      );

      // Distance should be around 395 km
      expect(distance, inInclusiveRange(380.0, 410.0));
    });

    test('calculateDistance for same point should be 0', () {
      const lat1 = 24.7136;
      const lon1 = 46.6753;

      final distance = DistanceCalculator.haversine(
        lat1: lat1,
        lon1: lon1,
        lat2: lat1,
        lon2: lon1,
      );

      expect(distance, 0.0);
    });
  });
}

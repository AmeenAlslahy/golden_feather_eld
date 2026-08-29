import '../../domain/entities/inspection_data.dart';

/// بيانات وهمية للتفتيش
class InspectionMockData {
  static List<InspectionDayData> getLast8Days() {
    final now = DateTime.now();
    return List.generate(8, (index) {
      final date = now.subtract(Duration(days: index));
      return InspectionDayData(
        date: date,
        drivingHours: 8.0 + (index % 3).toDouble(),
        onDutyHours: 2.0 + (index % 2).toDouble(),
        offDutyHours: 10.0 - (index % 2).toDouble(),
        sleeperHours: 4.0 + (index % 2).toDouble(),
        isCertified: index != 0,
      );
    });
  }
}

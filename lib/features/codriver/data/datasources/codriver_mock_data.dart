import '../../domain/entities/codriver.dart';

/// بيانات وهمية للسائقين المساعدين
class CoDriverMockData {
  static List<CoDriver> getCoDrivers() {
    return const [
      CoDriver(id: 'co1', name: 'Mohamed Ahmed', licenseNumber: 'CDL-001'),
      CoDriver(id: 'co2', name: 'Ali Hassan', licenseNumber: 'CDL-002'),
      CoDriver(id: 'co3', name: 'Omar Khalid', licenseNumber: 'CDL-003'),
      CoDriver(id: 'co4', name: 'Khaled Ibrahim', licenseNumber: 'CDL-004'),
    ];
  }
}

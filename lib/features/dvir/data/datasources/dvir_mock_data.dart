import '../../domain/entities/dvir_report.dart';

/// بيانات وهمية لـ DVIR
class DvirMockData {
  static List<DvirReport> getDvirs() {
    final now = DateTime.now();
    return [
      DvirReport(
        id: '1',
        type: InspectionType.preTrip,
        date: now,
        driverName: 'أمين الصلاحي',
        vehicleId: '646',
        trailerId: '1402',
        odometer: 125000.0,
        items: InspectionItem.values
            .map((item) => ItemInspectionResult(item: item))
            .toList(),
        dtcCodes: const ['P0420', 'P0301'],
        notes: 'فحص ما قبل الرحلة - جميع الأنظمة تعمل بشكل طبيعي',
        condition: VehicleCondition.safe,
        isSubmitted: true,
      ),
      DvirReport(
        id: '2',
        type: InspectionType.postTrip,
        date: now.subtract(const Duration(days: 1)),
        driverName: 'أمين الصلاحي',
        vehicleId: '646',
        odometer: 124500.0,
        items: InspectionItem.values.map((item) {
          final isDefective = item == InspectionItem.tires ||
              item == InspectionItem.lights;
          return ItemInspectionResult(
            item: item,
            isDefective: isDefective,
            defectDescription: isDefective ? 'يحتاج صيانة' : null,
          );
        }).toList(),
        notes: 'الإطار الخلفي الأيسر بحاجة لتغيير. المصباح الأمامي الأيمن خافت.',
        condition: VehicleCondition.needsRepair,
        isSubmitted: true,
      ),
      DvirReport(
        id: '3',
        type: InspectionType.preTrip,
        date: now.subtract(const Duration(days: 2)),
        driverName: 'أمين الصلاحي',
        vehicleId: '646',
        odometer: 124000.0,
        items: InspectionItem.values
            .map((item) => ItemInspectionResult(item: item))
            .toList(),
        condition: VehicleCondition.safe,
        isSubmitted: true,
      ),
    ];
  }
}
